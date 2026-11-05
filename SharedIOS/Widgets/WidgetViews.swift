import SwiftUI
import WidgetKit

/// Timeline entry for the status widgets.
struct CrewEntry: TimelineEntry {
    let date: Date
    let snapshot: CrewSnapshot
}

/// Background drawn behind each Home Screen widget.
struct CrewWidgetBackground: View {
    let snapshot: CrewSnapshot
    let family: WidgetFamily

    var body: some View {
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            Color.clear
        default:
            LinearGradient(
                colors: [snapshot.mascot.tint, snapshot.mascot.wash],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }
}

/// All status widget layouts, chosen by family.
struct CrewWidgetView: View {
    let entry: CrewEntry
    let family: WidgetFamily

    var body: some View {
        switch family {
        case .systemSmall: SmallCrewWidget(snapshot: entry.snapshot, now: entry.date)
        case .systemMedium: MediumCrewWidget(snapshot: entry.snapshot, now: entry.date)
        case .systemLarge: LargeCrewWidget(snapshot: entry.snapshot, now: entry.date)
        case .accessoryCircular: CircularCrewWidget(snapshot: entry.snapshot, now: entry.date)
        case .accessoryRectangular: RectangularCrewWidget(snapshot: entry.snapshot, now: entry.date)
        case .accessoryInline: InlineCrewWidget(snapshot: entry.snapshot, now: entry.date)
        default: SmallCrewWidget(snapshot: entry.snapshot, now: entry.date)
        }
    }
}

private extension CrewSnapshot {
    func running(at date: Date) -> ActiveSession? {
        guard let a = active, !a.isFinished(at: date) else { return nil }
        return a
    }
}

/// Live countdown that keeps ticking inside widgets without timeline reloads.
struct SessionCountdown: View {
    let session: ActiveSession
    var font: Font = .rounded(size: 30, weight: .heavy)
    var color: Color = Theme.ink

    var body: some View {
        Group {
            if session.isPaused {
                Text(Format.clock(session.remaining()))
            } else {
                Text(timerInterval: session.countdownRange, countsDown: true)
            }
        }
        .font(font)
        .monospacedDigit()
        .foregroundStyle(color)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}

// MARK: - Small

struct SmallCrewWidget: View {
    let snapshot: CrewSnapshot
    let now: Date

    var body: some View {
        let m = snapshot.mascot
        ZStack(alignment: .bottomTrailing) {
            Image(m.asset(snapshot.running(at: now) == nil ? m.restingMood : .focused))
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .offset(x: 18, y: 20)
            VStack(alignment: .leading, spacing: 2) {
                if let s = snapshot.running(at: now) {
                    HStack(spacing: 4) {
                        Circle().fill(m.accent).frame(width: 7, height: 7)
                        Text(s.kind == .rest ? "BREAK" : (s.isPaused ? "PAUSED" : "FOCUSING"))
                            .font(.rounded(.caption2, weight: .heavy))
                            .foregroundStyle(m.accent)
                    }
                    SessionCountdown(session: s, font: .rounded(size: 28, weight: .heavy))
                        .frame(maxWidth: 110, alignment: .leading)
                    Text("with \(m.name)")
                        .font(.rounded(.caption, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                } else {
                    Text("TODAY")
                        .font(.rounded(.caption2, weight: .heavy))
                        .foregroundStyle(m.accent)
                    Text(Format.duration(seconds: snapshot.todayFocusSeconds))
                        .font(.rounded(size: 30, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                        .minimumScaleFactor(0.6)
                    Text("of \(Format.duration(minutes: snapshot.dailyGoalMinutes)) goal")
                        .font(.rounded(.caption, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer(minLength: 0)
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill").foregroundStyle(Theme.flame)
                    Text("\(snapshot.streak)")
                        .foregroundStyle(Theme.ink)
                }
                .font(.rounded(.subheadline, weight: .heavy))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .widgetURL(URL(string: snapshot.active == nil ? "focuscrew://home" : "focuscrew://session"))
    }
}

// MARK: - Medium

struct MediumCrewWidget: View {
    let snapshot: CrewSnapshot
    let now: Date

    var body: some View {
        let m = snapshot.mascot
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Theme.surface.opacity(0.55))
                Image(m.asset(snapshot.running(at: now) == nil ? .happy : .focused))
                    .resizable()
                    .scaledToFit()
                    .padding(4)
            }
            .frame(width: 128, height: 128)

            VStack(alignment: .leading, spacing: 6) {
                if let s = snapshot.running(at: now) {
                    Text(s.kind == .rest ? "On a break" : (s.isPaused ? "Paused" : "Focusing with \(m.name)"))
                        .font(.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(Theme.inkSecondary)
                        .lineLimit(1)
                    SessionCountdown(session: s, font: .rounded(size: 38, weight: .heavy))
                    if !s.intention.isEmpty {
                        Text(s.intention)
                            .font(.rounded(.caption, weight: .semibold))
                            .foregroundStyle(Theme.inkSecondary)
                            .lineLimit(1)
                    }
                    if !s.isPaused {
                        ProgressView(timerInterval: s.countdownRange, countsDown: false) {
                            EmptyView()
                        } currentValueLabel: {
                            EmptyView()
                        }
                        .tint(m.accent)
                    }
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(Format.duration(seconds: snapshot.todayFocusSeconds))
                            .font(.rounded(size: 32, weight: .heavy))
                            .foregroundStyle(Theme.ink)
                        Text("today")
                            .font(.rounded(.subheadline, weight: .bold))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    WidgetBar(progress: snapshot.goalProgress, tint: m.accent)
                    HStack(spacing: 10) {
                        Label("\(snapshot.streak)", systemImage: "flame.fill")
                        Label(Format.duration(minutes: snapshot.dailyGoalMinutes), systemImage: "target")
                    }
                    .font(.rounded(.caption, weight: .bold))
                    .foregroundStyle(Theme.inkSecondary)
                    Link(destination: URL(string: "focuscrew://start?minutes=\(snapshot.defaultMinutes)")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("Focus \(snapshot.defaultMinutes) min")
                        }
                        .font(.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(Theme.inkInverse)
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .background(Capsule().fill(Theme.ink))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .widgetURL(URL(string: snapshot.active == nil ? "focuscrew://home" : "focuscrew://session"))
    }
}

struct WidgetBar: View {
    var progress: Double
    var tint: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surface.opacity(0.7))
                Capsule().fill(tint).frame(width: max(8, geo.size.width * min(1, progress)))
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Large

struct LargeCrewWidget: View {
    let snapshot: CrewSnapshot
    let now: Date

    var body: some View {
        let m = snapshot.mascot
        let maxMinutes = max(snapshot.dailyGoalMinutes, snapshot.weekMinutes.max() ?? 1, 1)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.running(at: now) == nil ? "Hi \(snapshot.name)!" : "Focusing")
                        .font(.rounded(.title3, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Text(snapshot.running(at: now) == nil ? m.line(from: m.greetings, seed: Calendar.current.component(.hour, from: now)) : "with \(m.name)")
                        .font(.rounded(.caption, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .lineLimit(2)
                }
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill").foregroundStyle(Theme.flame)
                    Text("\(snapshot.streak)").foregroundStyle(Theme.ink)
                }
                .font(.rounded(.headline, weight: .heavy))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(Theme.surface.opacity(0.8)))
            }
            HStack(spacing: 4) {
                Image(m.asset(snapshot.running(at: now) == nil ? .happy : .focused))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                VStack(alignment: .leading, spacing: 4) {
                    if let s = snapshot.running(at: now) {
                        SessionCountdown(session: s, font: .rounded(size: 44, weight: .heavy))
                        Text(s.intention.isEmpty ? "Stay with it!" : s.intention)
                            .font(.rounded(.subheadline, weight: .semibold))
                            .foregroundStyle(Theme.inkSecondary)
                            .lineLimit(2)
                    } else {
                        Text(Format.duration(seconds: snapshot.todayFocusSeconds))
                            .font(.rounded(size: 40, weight: .heavy))
                            .foregroundStyle(Theme.ink)
                        Text("focused today")
                            .font(.rounded(.subheadline, weight: .semibold))
                            .foregroundStyle(Theme.inkSecondary)
                        WidgetBar(progress: snapshot.goalProgress, tint: m.accent)
                            .padding(.top, 4)
                        Text("\(Int(snapshot.goalProgress * 100))% of \(Format.duration(minutes: snapshot.dailyGoalMinutes))")
                            .font(.rounded(.caption, weight: .bold))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("This week")
                    .font(.rounded(.caption, weight: .heavy))
                    .foregroundStyle(Theme.inkSecondary)
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(snapshot.weekMinutes.enumerated()), id: \.offset) { i, minutes in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(i == snapshot.weekMinutes.count - 1 ? m.accent : m.accent.opacity(0.4))
                                .frame(height: max(6, 70 * CGFloat(minutes) / CGFloat(maxMinutes)))
                            Text(dayLetter(offset: snapshot.weekMinutes.count - 1 - i))
                                .font(.rounded(.caption2, weight: .bold))
                                .foregroundStyle(Theme.inkTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 92, alignment: .bottom)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface.opacity(0.75)))
            if snapshot.running(at: now) == nil {
                Link(destination: URL(string: "focuscrew://start?minutes=\(snapshot.defaultMinutes)")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                        Text("Start a \(snapshot.defaultMinutes)-minute session")
                    }
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(Theme.inkInverse)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Capsule().fill(Theme.ink))
                }
            }
        }
        .widgetURL(URL(string: snapshot.active == nil ? "focuscrew://home" : "focuscrew://session"))
    }

    private func dayLetter(offset: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -offset, to: now) ?? now
        let index = Calendar.current.component(.weekday, from: date) - 1
        return Calendar.current.veryShortWeekdaySymbols[index]
    }
}

// MARK: - Lock Screen

struct CircularCrewWidget: View {
    let snapshot: CrewSnapshot
    let now: Date

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let s = snapshot.running(at: now), !s.isPaused {
                ProgressView(timerInterval: s.countdownRange, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    Image(systemName: s.kind == .rest ? "cup.and.saucer.fill" : "scope")
                        .font(.system(size: 18, weight: .bold))
                }
                .progressViewStyle(.circular)
            } else {
                Gauge(value: snapshot.goalProgress) {
                    Image(systemName: "scope")
                } currentValueLabel: {
                    Text("\(snapshot.todayFocusSeconds / 60)")
                        .font(.rounded(.title3, weight: .heavy))
                }
                .gaugeStyle(.accessoryCircularCapacity)
            }
        }
        .widgetURL(URL(string: "focuscrew://home"))
    }
}

struct RectangularCrewWidget: View {
    let snapshot: CrewSnapshot
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let s = snapshot.running(at: now) {
                Text(s.kind == .rest ? "Break · \(snapshot.mascot.name)" : "Focusing · \(snapshot.mascot.name)")
                    .font(.rounded(.caption, weight: .bold))
                    .widgetAccentable()
                SessionCountdown(session: s, font: .rounded(size: 24, weight: .heavy), color: .primary)
                if !s.isPaused {
                    ProgressView(timerInterval: s.countdownRange, countsDown: false) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                }
            } else {
                Text("\(snapshot.mascot.name) · \(snapshot.streak)-day streak")
                    .font(.rounded(.caption, weight: .bold))
                    .widgetAccentable()
                Text("\(Format.duration(seconds: snapshot.todayFocusSeconds)) focused")
                    .font(.rounded(.headline, weight: .heavy))
                Gauge(value: snapshot.goalProgress) { EmptyView() }
                    .gaugeStyle(.accessoryLinearCapacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(URL(string: "focuscrew://home"))
    }
}

struct InlineCrewWidget: View {
    let snapshot: CrewSnapshot
    let now: Date

    var body: some View {
        if let s = snapshot.running(at: now), !s.isPaused {
            Label {
                Text(timerInterval: s.countdownRange, countsDown: true)
            } icon: {
                Image(systemName: "scope")
            }
        } else {
            Label("\(Format.duration(seconds: snapshot.todayFocusSeconds)) focused · \(snapshot.streak)🔥", systemImage: "scope")
        }
    }
}
