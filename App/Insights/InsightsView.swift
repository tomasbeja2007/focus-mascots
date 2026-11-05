import Charts
import DeviceActivity
import SwiftUI

/// The Insights tab: focus charts, records, Screen Time report and history.
struct InsightsView: View {
    @Environment(AppModel.self) private var model

    enum Range: String, CaseIterable, Identifiable {
        case week = "Week", month = "Month"
        var id: String { rawValue }
        var days: Int { self == .week ? 7 : 30 }
    }

    @State private var range: Range = .week

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Picker("Range", selection: $range) {
                        ForEach(Range.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    summaryGrid
                    chartCard
                    blobInsight
                    hoursCard
                    screenTimeCard
                    historySection
                }
                .padding(.horizontal, Theme.pagePadding)
                .padding(.bottom, 32)
            }
            .pageBackground()
            .navigationTitle("Insights")
        }
    }

    private var days: [DayTotal] { model.stats.dailyMinutes(lastDays: range.days) }

    private var rangeMinutes: Int { days.reduce(0) { $0 + $1.minutes } }

    private var previousRangeMinutes: Int {
        let cal = Calendar.current
        guard let end = cal.date(byAdding: .day, value: -range.days, to: Date()) else { return 0 }
        return model.stats.dailyMinutes(lastDays: range.days, endingAt: end).reduce(0) { $0 + $1.minutes }
    }

    // MARK: Summary

    private var summaryGrid: some View {
        let st = model.stats
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -(range.days - 1), to: cal.startOfDay(for: Date())) ?? Date()
        let sessions = st.focusSessions.filter { $0.startedAt >= start }
        let completed = sessions.filter(\.completed).count
        let rate = sessions.isEmpty ? 0 : Double(completed) / Double(sessions.count)
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatTile(value: Format.duration(minutes: rangeMinutes), label: "focused this \(range.rawValue.lowercased())", symbol: "clock.fill", tint: model.mascot.accent)
            StatTile(value: "\(completed)", label: "sessions completed", symbol: "checkmark.circle.fill", tint: Theme.success)
            StatTile(value: "\(st.currentStreak()) / \(st.bestStreak())", label: "streak / best", symbol: "flame.fill", tint: Theme.flame)
            StatTile(value: "\(Int(rate * 100))%", label: "completion rate", symbol: "target", tint: Color("BlobAccent"))
        }
    }

    // MARK: Chart

    private var chartCard: some View {
        let goal = model.settings.dailyGoalMinutes
        let delta = rangeMinutes - previousRangeMinutes
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Focus time")
                        .font(.rounded(.headline, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Daily average \(Format.duration(minutes: rangeMinutes / max(1, range.days)))")
                        .font(.rounded(.footnote, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer()
                if previousRangeMinutes > 0 || rangeMinutes > 0 {
                    Label("\(delta >= 0 ? "+" : "")\(Format.duration(minutes: abs(delta)))", systemImage: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.rounded(.caption, weight: .bold))
                        .foregroundStyle(delta >= 0 ? Theme.success : Theme.danger)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill((delta >= 0 ? Theme.success : Theme.danger).opacity(0.12)))
                }
            }
            Chart {
                ForEach(days) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Minutes", day.minutes)
                    )
                    .foregroundStyle(day.minutes >= goal ? model.mascot.accent : model.mascot.accent.opacity(0.45))
                    .cornerRadius(6)
                }
                RuleMark(y: .value("Goal", goal))
                    .foregroundStyle(Theme.inkTertiary)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal \(Format.duration(minutes: goal))")
                            .font(.rounded(.caption2, weight: .bold))
                            .foregroundStyle(Theme.inkTertiary)
                    }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: range == .week ? 1 : 7)) { _ in
                    AxisValueLabel(
                        format: range == .week ? Date.FormatStyle.dateTime.weekday(.narrow) : Date.FormatStyle.dateTime.day().month(.abbreviated),
                        centered: range == .week
                    )
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(Theme.hairline)
                    AxisValueLabel {
                        if let v = value.as(Int.self) { Text("\(v)m").font(.rounded(.caption2)) }
                    }
                }
            }
            .frame(height: 200)
        }
        .cardStyle(radius: Theme.cornerLarge)
    }

    private var blobInsight: some View {
        HStack(alignment: .top, spacing: 12) {
            MascotView(mascot: .blob, mood: .happy, size: 70, showDecoration: false, motion: .breathe)
            SpeechBubble(text: insightText, tailEdge: .leading, font: .rounded(.subheadline, weight: .semibold))
            Spacer(minLength: 0)
        }
    }

    private var insightText: String {
        let st = model.stats
        if st.focusSessions.isEmpty { return "Finish your first session and I'll start crunching numbers!" }
        if let hour = st.bestHour {
            let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
            return "You focus best around \(date.formatted(date: .omitted, time: .shortened)). Try scheduling deep work then!"
        }
        return "Every session adds up. Keep going!"
    }

    // MARK: Hours heat strip

    private var hoursCard: some View {
        let hist = model.stats.hourHistogram
        let maxValue = max(1, hist.max() ?? 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text("When you focus")
                .font(.rounded(.headline, weight: .bold))
                .foregroundStyle(Theme.ink)
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<24, id: \.self) { h in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(model.mascot.accent.opacity(0.15 + 0.85 * Double(hist[h]) / Double(maxValue)))
                        .frame(height: 10 + 50 * CGFloat(hist[h]) / CGFloat(maxValue))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 64, alignment: .bottom)
            HStack {
                Text("12 AM"); Spacer(); Text("6 AM"); Spacer(); Text("12 PM"); Spacer(); Text("6 PM"); Spacer(); Text("11 PM")
            }
            .font(.rounded(.caption2, weight: .semibold))
            .foregroundStyle(Theme.inkTertiary)
        }
        .cardStyle(radius: Theme.cornerLarge)
    }

    // MARK: Screen Time

    private var screenTimeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Screen time today")
                    .font(.rounded(.headline, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: "hourglass")
                    .foregroundStyle(Theme.inkSecondary)
            }
            if model.screenTime.isAuthorized {
                DeviceActivityReport(.totalActivity, filter: todayFilter)
                    .frame(height: 360)
                    .frame(maxWidth: .infinity)
            } else {
                Text("Connect Screen Time to see how much time you spend in each app. The numbers never leave your iPhone.")
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Connect Screen Time") {
                    Task { await model.screenTime.requestAuthorization() }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .cardStyle(radius: Theme.cornerLarge)
    }

    private var todayFilter: DeviceActivityFilter {
        let start = Calendar.current.startOfDay(for: Date())
        return DeviceActivityFilter(
            segment: .daily(during: DateInterval(start: start, end: Date())),
            users: .all,
            devices: .init([.iPhone, .iPad])
        )
    }

    // MARK: History

    private var historySection: some View {
        let recent = Array(model.stats.focusSessions.sorted { $0.startedAt > $1.startedAt }.prefix(12))
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent sessions")
            if recent.isEmpty {
                Text("Your sessions will show up here.")
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(Theme.inkTertiary)
                    .padding(.horizontal, 4)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recent.enumerated()), id: \.element.id) { index, s in
                        HStack(spacing: 12) {
                            MascotAvatar(mascot: s.mascot, size: 38)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(s.intention.isEmpty ? "Focus session" : s.intention)
                                    .font(.rounded(.subheadline, weight: .bold))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                                Text(s.startedAt.formatted(.dateTime.weekday(.abbreviated).hour().minute()))
                                    .font(.rounded(.caption, weight: .medium))
                                    .foregroundStyle(Theme.inkSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(Format.duration(seconds: s.focusedSeconds))
                                    .font(.rounded(.subheadline, weight: .heavy))
                                    .foregroundStyle(Theme.ink)
                                Text(s.completed ? "Completed" : "Ended early")
                                    .font(.rounded(.caption2, weight: .bold))
                                    .foregroundStyle(s.completed ? Theme.success : Theme.inkTertiary)
                            }
                        }
                        .padding(.vertical, 10)
                        if index < recent.count - 1 { Divider().padding(.leading, 50) }
                    }
                }
                .cardStyle(padding: 14, radius: Theme.cornerLarge)
            }
        }
    }
}
