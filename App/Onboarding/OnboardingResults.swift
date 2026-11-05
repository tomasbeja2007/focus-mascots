import SwiftUI

/// "At this pace you'll spend X years on your phone." Honest maths, no invented stats.
struct RealityCheckStep: View {
    let profile: UserProfile
    let onNext: () -> Void
    @State private var shown: Double = 0

    private var years: Double { MascotMatcher.yearsOnPhone(profile) }
    private var saved: Double { MascotMatcher.yearsSaved(cuttingHours: min(2, profile.dailyScreenHours / 2), profile) }
    private var hoursPerYear: Int { Int(profile.dailyScreenHours * 365) }

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 18) {
                HostBubble(mascot: .leaf, text: "Okay, deep breath\u{2026}", mood: .sad)
                Text("At your current pace, you'll spend")
                    .font(.rounded(.title2, weight: .bold))
                    .foregroundStyle(Theme.ink)

                VStack(spacing: 4) {
                    Text(String(format: "%.1f", shown))
                        .font(.rounded(size: 92, weight: .heavy))
                        .foregroundStyle(Theme.flame)
                        .contentTransition(.numericText(value: shown))
                        .monospacedDigit()
                    Text("years of your life on your phone")
                        .font(.rounded(.title3, weight: .bold))
                        .foregroundStyle(Theme.ink)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous).fill(Theme.flame.opacity(0.1)))

                HStack(spacing: 12) {
                    StatTile(value: "\(hoursPerYear.formatted())h", label: "every year", symbol: "calendar", tint: Theme.flame)
                    StatTile(value: "\(Int(profile.dailyScreenHours * 7))h", label: "every week", symbol: "clock.fill", tint: Theme.flame)
                }

                HStack(alignment: .top, spacing: 12) {
                    MascotAvatar(mascot: .spark, size: 44)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("The good news?")
                            .font(.rounded(.headline, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Text("Cutting just \(cutText) a day gives you back **\(String(format: "%.1f", saved)) years**. That's what we're here for.")
                            .font(.rounded(.subheadline, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .cardStyle()

                Text("Based on your estimate of \(formattedHours) hours a day until age 80.")
                    .font(.rounded(.caption))
                    .foregroundStyle(Theme.inkTertiary)
            }
        } footer: {
            Button("Let's change that", action: onNext)
                .buttonStyle(PrimaryButtonStyle())
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.6).delay(0.3)) { shown = years }
        }
    }

    private var cutText: String {
        let h = min(2, profile.dailyScreenHours / 2)
        if h >= 2 { return "2 hours" }
        if h >= 1 { return h == 1 ? "1 hour" : String(format: "%.1f hours", h) }
        return "\(Int(h * 60)) minutes"
    }

    private var formattedHours: String {
        profile.dailyScreenHours.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(profile.dailyScreenHours)) : String(format: "%.1f", profile.dailyScreenHours)
    }
}

/// Animated "building your plan" screen that runs the matcher.
struct AnalyzingStep: View {
    let profile: UserProfile
    let onDone: () -> Void

    @State private var progress: Double = 0
    @State private var checked = 0
    @State private var spotlight = 0

    private let items = [
        "Analysing your answers",
        "Mapping your distraction triggers",
        "Picking your session length",
        "Matching you with a companion",
        "Building your focus plan",
    ]

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                ProgressRing(progress: progress, lineWidth: 12, tint: Theme.ink, track: Theme.hairline)
                    .frame(width: 210, height: 210)
                MascotView(mascot: Mascot.allCases[spotlight % 5], mood: .idle, size: 170, showDecoration: false, motion: .breathe)
                    .id(spotlight)
                    .transition(.scale.combined(with: .opacity))
            }
            Text("\(Int(progress * 100))%")
                .font(.rounded(size: 40, weight: .heavy))
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText(value: progress))
                .monospacedDigit()
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(index < checked ? Theme.ink : Theme.hairline).frame(width: 24, height: 24)
                            if index < checked {
                                Image(systemName: "checkmark").font(.system(size: 12, weight: .heavy)).foregroundStyle(Theme.inkInverse)
                            }
                        }
                        Text(item)
                            .font(.rounded(.body, weight: index < checked ? .semibold : .medium))
                            .foregroundStyle(index < checked ? Theme.ink : Theme.inkTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 44)
            Spacer()
        }
        .task {
            let steps = 50
            for i in 1...steps {
                try? await Task.sleep(nanoseconds: 80_000_000)
                withAnimation(.easeInOut(duration: 0.15)) {
                    progress = Double(i) / Double(steps)
                    checked = min(items.count, Int(Double(i) / Double(steps) * Double(items.count + 1)))
                }
                if i % 8 == 0 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { spotlight += 1 }
                    Haptics.select()
                }
            }
            checked = items.count
            try? await Task.sleep(nanoseconds: 450_000_000)
            onDone()
        }
    }
}

/// "Your companion is…" with confetti and the reasons it was picked.
struct MascotRevealStep: View {
    @Binding var profile: UserProfile
    let onNext: () -> Void

    @State private var revealed = false
    @State private var showPicker = false

    private var mascot: Mascot { profile.mascot }

    var body: some View {
        ZStack {
            mascot.wash.ignoresSafeArea()
            OnboardingPage {
                VStack(spacing: 16) {
                    Text(profile.mascot == profile.matchedMascot ? "\(profile.firstName), your focus companion is\u{2026}" : "You picked\u{2026}")
                        .font(.rounded(.title3, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)
                    MascotView(mascot: mascot, mood: revealed ? .excited : .idle, size: 260, motion: revealed ? .bounce : .breathe)
                        .scaleEffect(revealed ? 1 : 0.3)
                        .opacity(revealed ? 1 : 0)
                    VStack(spacing: 6) {
                        Text(mascot.name)
                            .font(.rounded(size: 48, weight: .heavy))
                            .foregroundStyle(Theme.ink)
                        Text(mascot.title)
                            .font(.rounded(.title3, weight: .semibold))
                            .foregroundStyle(Theme.inkSecondary)
                        TraitChip(title: mascot.trait, symbol: mascot.traitSymbol, tint: mascot.accent, background: Theme.surface)
                            .padding(.top, 6)
                    }
                    .opacity(revealed ? 1 : 0)
                    .offset(y: revealed ? 0 : 20)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Why \(mascot.name)?")
                            .font(.rounded(.headline, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        ForEach(MascotMatcher.reasons(for: mascot, profile), id: \.self) { reason in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(mascot.accent)
                                    .font(.system(size: 18))
                                Text(reason)
                                    .font(.rounded(.subheadline, weight: .medium))
                                    .foregroundStyle(Theme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                    .opacity(revealed ? 1 : 0)
                }
            } footer: {
                Button("Continue with \(mascot.name)", action: onNext)
                    .buttonStyle(PrimaryButtonStyle())
                Button("Meet the others") { showPicker = true }
                    .buttonStyle(QuietButtonStyle())
            }
            if revealed {
                ConfettiView().ignoresSafeArea()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { revealed = true }
                Haptics.success()
            }
        }
        .sheet(isPresented: $showPicker) {
            MascotPickerSheet(selected: profile.mascot, recommended: profile.matchedMascot) { picked in
                profile.mascot = picked
                showPicker = false
            }
            .presentationDetents([.large])
            .presentationCornerRadius(32)
        }
    }
}

/// Grid of all five mascots to choose from.
struct MascotPickerSheet: View {
    let selected: Mascot
    var recommended: Mascot?
    let onPick: (Mascot) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Mascot.allCases) { m in
                        Button { onPick(m) } label: {
                            HStack(spacing: 14) {
                                MascotView(mascot: m, mood: m.restingMood, size: 92, motion: .still)
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(m.name).font(.rounded(.title3, weight: .bold)).foregroundStyle(Theme.ink)
                                        if m == recommended {
                                            Text("BEST MATCH")
                                                .font(.rounded(.caption2, weight: .heavy))
                                                .foregroundStyle(m.accent)
                                                .padding(.horizontal, 6).padding(.vertical, 3)
                                                .background(Capsule().fill(m.tint))
                                        }
                                    }
                                    Text(m.title).font(.rounded(.subheadline, weight: .semibold)).foregroundStyle(Theme.inkSecondary)
                                    Text(m.specialty).font(.rounded(.footnote)).foregroundStyle(Theme.inkTertiary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: m == selected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(m == selected ? Theme.ink : Theme.inkTertiary)
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.surface))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                                    .strokeBorder(m == selected ? Theme.ink : Theme.hairline, lineWidth: m == selected ? 2 : 1)
                            )
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(Theme.pagePadding)
            }
            .pageBackground()
            .navigationTitle("Choose your companion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.font(.rounded(.body, weight: .semibold))
                }
            }
        }
    }
}

/// The personalised plan.
struct PlanStep: View {
    let profile: UserProfile
    let goalMinutes: Int
    let onNext: () -> Void

    private var mascot: Mascot { profile.mascot }
    private var session: Int { profile.focusSpan?.suggestedSessionMinutes ?? mascot.defaultMinutes }

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    MascotAvatar(mascot: mascot, size: 52)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your plan is ready")
                            .font(.rounded(.caption, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(mascot.accent)
                        Text("\(profile.firstName)'s focus plan")
                            .font(.rounded(.title, weight: .bold))
                            .foregroundStyle(Theme.ink)
                    }
                }

                VStack(spacing: 0) {
                    planRow("target", "Daily focus goal", Format.longDuration(minutes: goalMinutes))
                    Divider().padding(.leading, 58)
                    planRow("timer", "Session length", "\(session) min")
                    Divider().padding(.leading, 58)
                    planRow("cup.and.saucer.fill", "Breaks", profile.struggles.contains(.breaks) ? "10 min" : "5 min")
                    Divider().padding(.leading, 58)
                    planRow("lock.fill", "Block during focus", blockText)
                    Divider().padding(.leading, 58)
                    planRow(mascot.prefersStrictMode ? "hand.raised.fill" : "hand.thumbsup.fill", "Coaching style", mascot.prefersStrictMode ? "Strict" : "Supportive")
                    if profile.struggles.contains(.sleep) || profile.hardestTimes.contains(.bedtime) {
                        Divider().padding(.leading, 58)
                        planRow("moon.stars.fill", "Bedtime block", "10:30 PM – 7:00 AM")
                    }
                }
                .cardStyle(padding: 6)

                ProjectionCard(profile: profile, goalMinutes: goalMinutes)
            }
        } footer: {
            Button("Looks good", action: onNext)
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var blockText: String {
        let names = profile.timeSinks.prefix(2).map { $0.title }
        if names.isEmpty { return "Your choice" }
        return names.joined(separator: ", ")
    }

    private func planRow(_ symbol: String, _ title: String, _ value: String) -> some View {
        HStack(spacing: 12) {
            IconBadge(symbol: symbol, tint: mascot.accent, background: mascot.tint.opacity(0.55), size: 36)
            Text(title)
                .font(.rounded(.body, weight: .medium))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text(value)
                .font(.rounded(.body, weight: .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
    }
}

/// A gentle projection of weekly focus hours over the first month.
struct ProjectionCard: View {
    let profile: UserProfile
    let goalMinutes: Int

    private var weeks: [Double] {
        let target = Double(goalMinutes * 7) / 60
        return [0.35, 0.6, 0.82, 1.0].map { target * $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your first 4 weeks")
                .font(.rounded(.headline, weight: .bold))
                .foregroundStyle(Theme.ink)
            HStack(alignment: .bottom, spacing: 14) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { i, hours in
                    VStack(spacing: 6) {
                        Text("\(Int(hours.rounded()))h")
                            .font(.rounded(.caption, weight: .bold))
                            .foregroundStyle(i == 3 ? profile.mascot.accent : Theme.inkSecondary)
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(i == 3 ? profile.mascot.accent : profile.mascot.tint)
                            .frame(height: CGFloat(30 + 100 * (hours / max(1, weeks.last ?? 1))))
                        Text("Week \(i + 1)")
                            .font(.rounded(.caption2, weight: .semibold))
                            .foregroundStyle(Theme.inkTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 170, alignment: .bottom)
            Text("Build up gradually to \(Format.longDuration(minutes: goalMinutes)) of focus a day. Small steps, real change.")
                .font(.rounded(.footnote, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
        }
        .cardStyle()
    }
}

struct DailyGoalStep: View {
    let profile: UserProfile
    @Binding var goalMinutes: Int
    let onNext: () -> Void

    private let options = [30, 60, 90, 120, 180, 240]
    private var recommended: Int { profile.focusSpan?.suggestedDailyGoalMinutes ?? 90 }

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 18) {
                HostBubble(mascot: .blob, text: "Pick a goal you can hit on a normal day.")
                Text("Set your daily focus goal")
                    .font(.rounded(.title, weight: .bold))
                    .foregroundStyle(Theme.ink)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(options, id: \.self) { minutes in
                        let selected = goalMinutes == minutes
                        Button {
                            Haptics.select()
                            goalMinutes = minutes
                        } label: {
                            VStack(spacing: 4) {
                                Text(Format.duration(minutes: minutes))
                                    .font(.rounded(.title2, weight: .heavy))
                                    .foregroundStyle(selected ? Theme.inkInverse : Theme.ink)
                                Text(label(for: minutes))
                                    .font(.rounded(.caption, weight: .semibold))
                                    .foregroundStyle(selected ? Theme.inkInverse.opacity(0.75) : Theme.inkSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 92)
                            .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(selected ? Theme.ink : Theme.surface))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                                    .strokeBorder(Theme.hairline, lineWidth: selected ? 0 : 1)
                            )
                            .overlay(alignment: .topTrailing) {
                                if minutes == recommended {
                                    Text("For you")
                                        .font(.rounded(.caption2, weight: .heavy))
                                        .foregroundStyle(profile.mascot.accent)
                                        .padding(.horizontal, 7).padding(.vertical, 3)
                                        .background(Capsule().fill(profile.mascot.tint))
                                        .padding(8)
                                }
                            }
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                Text("You can change this any time in Settings.")
                    .font(.rounded(.footnote))
                    .foregroundStyle(Theme.inkTertiary)
            }
        } footer: {
            Button("Set goal", action: onNext)
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    private func label(for minutes: Int) -> String {
        switch minutes {
        case ..<45: return "Easy start"
        case ..<75: return "Steady"
        case ..<100: return "Balanced"
        case ..<150: return "Ambitious"
        case ..<200: return "Deep worker"
        default: return "Beast mode"
        }
    }
}
