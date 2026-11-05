import SwiftUI

extension OnboardingStep {
    /// What the host says above each question.
    var hostLine: String {
        switch self {
        case .age: return "Let's get to know you!"
        case .role: return "What fills your days?"
        case .screenTime: return "I love numbers. Give me one!"
        case .struggles: return "No judgement here. Pinky promise."
        case .timeSinks: return "Which apps pull you in?"
        case .hardestTimes: return "Timing matters a lot."
        case .focusSpan: return "Quick check of your focus muscles!"
        case .goal: return "What would make life better?"
        case .motivation: return "Last one! This decides who joins you."
        default: return ""
        }
    }

    var questionNumber: Int { (OnboardingStep.questions.firstIndex(of: self) ?? 0) + 1 }
}

/// A tappable answer card.
struct OptionCard: View {
    let title: String
    let symbol: String
    let selected: Bool
    var multi: Bool = false
    var accent: Color = Theme.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                IconBadge(
                    symbol: symbol,
                    tint: selected ? Theme.inkInverse : Theme.ink,
                    background: selected ? Theme.ink : Theme.surfaceMuted,
                    size: 40
                )
                Text(title)
                    .font(.rounded(.body, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                indicator
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .strokeBorder(selected ? Theme.ink : Theme.hairline, lineWidth: selected ? 2 : 1)
            )
            .shadow(color: .black.opacity(selected ? 0.06 : 0.02), radius: 8, y: 3)
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder
    private var indicator: some View {
        if multi {
            Image(systemName: selected ? "checkmark.square.fill" : "square")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(selected ? Theme.ink : Theme.inkTertiary)
        } else {
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(selected ? Theme.ink : Theme.inkTertiary)
        }
    }
}

struct QuestionHeader: View {
    let step: OnboardingStep
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HostBubble(mascot: step.host, text: step.hostLine)
            Text("QUESTION \(step.questionNumber) OF \(OnboardingStep.questions.count)")
                .font(.rounded(.caption, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(step.host.accent)
            Text(title)
                .font(.rounded(.title, weight: .bold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.rounded(.subheadline, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
        }
    }
}

struct SingleChoiceStep<Option: QuizOption>: View {
    let step: OnboardingStep
    let title: String
    let subtitle: String
    let options: [Option]
    @Binding var selection: Option?
    let onNext: () -> Void

    @State private var advancing = false

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 18) {
                QuestionHeader(step: step, title: title, subtitle: subtitle)
                VStack(spacing: 10) {
                    ForEach(options) { option in
                        OptionCard(title: option.title, symbol: option.symbol, selected: selection == option) {
                            Haptics.select()
                            selection = option
                            guard !advancing else { return }
                            advancing = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                advancing = false
                                onNext()
                            }
                        }
                    }
                }
            }
        } footer: {
            Button("Continue", action: onNext)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selection == nil)
        }
    }
}

struct MultiChoiceStep<Option: QuizOption>: View {
    let step: OnboardingStep
    let title: String
    let subtitle: String
    let options: [Option]
    @Binding var selection: [Option]
    let onNext: () -> Void

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 18) {
                QuestionHeader(step: step, title: title, subtitle: subtitle)
                VStack(spacing: 10) {
                    ForEach(options) { option in
                        OptionCard(title: option.title, symbol: option.symbol, selected: selection.contains(option), multi: true) {
                            Haptics.select()
                            if let i = selection.firstIndex(of: option) {
                                selection.remove(at: i)
                            } else {
                                selection.append(option)
                            }
                        }
                    }
                }
            }
        } footer: {
            Button(selection.isEmpty ? "Pick at least one" : "Continue (\(selection.count))", action: onNext)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selection.isEmpty)
        }
    }
}

/// "How many hours a day are you on your phone?" with a live mascot reaction.
struct ScreenTimeEstimateStep: View {
    @Binding var hours: Double
    let onNext: () -> Void

    private var mood: MascotMood {
        switch hours {
        case ..<3: return .happy
        case ..<5: return .idle
        case ..<8: return .sad
        default: return .sad
        }
    }

    private var reaction: String {
        switch hours {
        case ..<2: return "Impressive! Let's keep it that way."
        case ..<4: return "Pretty average. We can do better!"
        case ..<6: return "That adds up fast. We'll fix this together."
        case ..<9: return "Oof. That's a part-time job."
        default: return "Yikes! Good thing you found us."
        }
    }

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 18) {
                QuestionHeader(
                    step: .screenTime,
                    title: "How many hours a day do you spend on your phone?",
                    subtitle: "A rough guess is fine. You can check in Settings \u{203A} Screen Time."
                )
                VStack(spacing: 6) {
                    MascotView(mascot: .blob, mood: mood, size: 150, motion: .breathe)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(hours >= 12 ? "12+" : formatted)
                            .font(.rounded(size: 64, weight: .heavy))
                            .foregroundStyle(Theme.ink)
                            .contentTransition(.numericText(value: hours))
                            .monospacedDigit()
                        Text(hours == 1 ? "hour" : "hours")
                            .font(.rounded(.title2, weight: .bold))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    Text(reaction)
                        .font(.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .animation(.none, value: hours)
                    Slider(value: $hours, in: 1...12, step: 0.5)
                        .tint(Color("BlobAccent"))
                        .padding(.top, 14)
                        .onChange(of: hours) { _, _ in Haptics.select() }
                    HStack {
                        Text("1h")
                        Spacer()
                        Text("6h")
                        Spacer()
                        Text("12h+")
                    }
                    .font(.rounded(.caption, weight: .semibold))
                    .foregroundStyle(Theme.inkTertiary)
                }
                .frame(maxWidth: .infinity)
                .cardStyle(padding: 20, radius: Theme.cornerLarge)
                .animation(.spring(response: 0.3), value: hours)
            }
        } footer: {
            Button("Continue", action: onNext)
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var formatted: String {
        hours.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(hours)) : String(format: "%.1f", hours)
    }
}
