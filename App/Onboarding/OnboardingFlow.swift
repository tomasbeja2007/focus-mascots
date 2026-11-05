import SwiftUI

/// Every screen of onboarding, in order.
enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case introBlock, introFocus, introProgress
    case name
    // The nine questions
    case age, role, screenTime, struggles, timeSinks, hardestTimes, focusSpan, goal, motivation
    // Results
    case reality, analyzing, reveal, plan, dailyGoal
    // Setup
    case screenTimePermission, chooseApps, notifications, pledge, paywall

    var id: Int { rawValue }

    static let questions: [OnboardingStep] = [.age, .role, .screenTime, .struggles, .timeSinks, .hardestTimes, .focusSpan, .goal, .motivation]

    var isQuestion: Bool { OnboardingStep.questions.contains(self) }

    var showsHeader: Bool {
        switch self {
        case .welcome, .analyzing, .reveal, .paywall: return false
        default: return true
        }
    }

    /// The crew member who asks the question.
    var host: Mascot {
        switch self {
        case .age, .hardestTimes, .introFocus, .name: return .orbit
        case .role, .focusSpan, .notifications: return .spark
        case .screenTime, .motivation, .introProgress, .plan, .dailyGoal: return .blob
        case .struggles, .introBlock, .screenTimePermission, .chooseApps, .pledge: return .pebble
        case .timeSinks, .goal, .reality: return .leaf
        default: return .orbit
        }
    }

    var progress: Double {
        Double(rawValue) / Double(OnboardingStep.allCases.count - 1)
    }
}

struct OnboardingFlow: View {
    @Environment(AppModel.self) private var model

    @State private var step: OnboardingStep
    @State private var draft: UserProfile
    @State private var goalMinutes: Int
    @State private var forward = true

    init(start: OnboardingStep = .welcome, draft: UserProfile = UserProfile()) {
        _step = State(initialValue: start)
        _draft = State(initialValue: draft)
        _goalMinutes = State(initialValue: draft.focusSpan?.suggestedDailyGoalMinutes ?? 90)
    }

    var body: some View {
        VStack(spacing: 0) {
            if step.showsHeader {
                OnboardingHeader(progress: step.progress, canGoBack: step != .welcome, onBack: back)
                    .padding(.horizontal, Theme.pagePadding)
                    .padding(.top, 8)
            }
            ZStack {
                stepView
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
                    ))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .pageBackground()
        .animation(.spring(response: 0.5, dampingFraction: 0.86), value: step)
    }

    @ViewBuilder
    private var stepView: some View {
        switch step {
        case .welcome:
            WelcomeStep(onNext: next)
        case .introBlock:
            IntroStep(
                mascot: .pebble, mood: .focused,
                title: "Block the apps that steal your time",
                subtitle: "Pick your distractions once. Pebble locks them during focus sessions and on your schedule.",
                bullets: [("lock.fill", "Apps, categories and websites"), ("calendar.badge.clock", "Automatic schedules"), ("hand.raised.fill", "Strict mode for tough days")],
                onNext: next
            )
        case .introFocus:
            IntroStep(
                mascot: .orbit, mood: .focused,
                title: "Focus with a friend by your side",
                subtitle: "Start a timer and your companion focuses with you: on the Lock Screen, the Dynamic Island and even next to your Mac's notch.",
                bullets: [("timer", "Focus timer with breaks"), ("iphone.gen3", "Live Activity & widgets"), ("laptopcomputer", "Mac notch companion")],
                onNext: next
            )
        case .introProgress:
            IntroStep(
                mascot: .blob, mood: .happy,
                title: "Watch your progress grow",
                subtitle: "Every focused minute counts. Build streaks, unlock badges and grow your bond with the crew.",
                bullets: [("flame.fill", "Daily streaks"), ("chart.bar.fill", "Weekly insights"), ("rosette", "16 badges to collect")],
                onNext: next
            )
        case .name:
            NameStep(name: $draft.name, onNext: next)
        case .age:
            SingleChoiceStep(step: step, title: "How old are you?", subtitle: "This helps us tailor your plan.", options: AgeRange.allCases, selection: $draft.age, onNext: next)
        case .role:
            SingleChoiceStep(step: step, title: "What best describes you?", subtitle: "We'll suggest sessions that fit your days.", options: LifeRole.allCases, selection: $draft.role, onNext: next)
        case .screenTime:
            ScreenTimeEstimateStep(hours: $draft.dailyScreenHours, onNext: next)
        case .struggles:
            MultiChoiceStep(step: step, title: "What do you struggle with most?", subtitle: "Pick everything that sounds like you.", options: Struggle.allCases, selection: $draft.struggles, onNext: next)
        case .timeSinks:
            MultiChoiceStep(step: step, title: "Where does your time disappear?", subtitle: "We'll suggest these for your block list.", options: TimeSink.allCases, selection: $draft.timeSinks, onNext: next)
        case .hardestTimes:
            MultiChoiceStep(step: step, title: "When is it hardest to put your phone down?", subtitle: "Pick all that apply.", options: DayPart.allCases, selection: $draft.hardestTimes, onNext: next)
        case .focusSpan:
            SingleChoiceStep(step: step, title: "How long can you focus before reaching for your phone?", subtitle: "Be honest, there's no wrong answer.", options: FocusSpan.allCases, selection: $draft.focusSpan, onNext: next)
        case .goal:
            SingleChoiceStep(step: step, title: "What's your main goal?", subtitle: "Your crew will cheer you on towards it.", options: MainGoal.allCases, selection: $draft.goal, onNext: next)
        case .motivation:
            SingleChoiceStep(step: step, title: "How do you like to be motivated?", subtitle: "This decides who joins you.", options: MotivationStyle.allCases, selection: $draft.motivation, onNext: next)
        case .reality:
            RealityCheckStep(profile: draft, onNext: next)
        case .analyzing:
            AnalyzingStep(profile: draft, onDone: {
                let result = MascotMatcher.match(draft)
                draft.matchedMascot = result.mascot
                draft.mascot = result.mascot
                goalMinutes = draft.focusSpan?.suggestedDailyGoalMinutes ?? 90
                next()
            })
        case .reveal:
            MascotRevealStep(profile: $draft, onNext: next)
        case .plan:
            PlanStep(profile: draft, goalMinutes: goalMinutes, onNext: next)
        case .dailyGoal:
            DailyGoalStep(profile: draft, goalMinutes: $goalMinutes, onNext: next)
        case .screenTimePermission:
            ScreenTimePermissionStep(onNext: next)
        case .chooseApps:
            ChooseAppsStep(profile: draft, onNext: next)
        case .notifications:
            NotificationsStep(mascot: draft.mascot, onNext: next)
        case .pledge:
            PledgeStep(profile: draft, goalMinutes: goalMinutes, onNext: {
                draft.pledgedAt = Date()
                next()
            })
        case .paywall:
            PaywallView(mascot: draft.mascot, context: .onboarding, onFinish: finish)
        }
    }

    private func next() {
        guard let nextStep = OnboardingStep(rawValue: step.rawValue + 1) else {
            finish()
            return
        }
        Haptics.tap()
        forward = true
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { step = nextStep }
    }

    private func back() {
        var target = step.rawValue - 1
        // Skip the automatic "analysing" screen when going back.
        if OnboardingStep(rawValue: target) == .analyzing { target -= 1 }
        guard let prev = OnboardingStep(rawValue: target) else { return }
        Haptics.tap()
        forward = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { step = prev }
    }

    private func finish() {
        let session = draft.focusSpan?.suggestedSessionMinutes ?? draft.mascot.defaultMinutes
        let profile = draft
        model.updateSettings {
            $0.dailyGoalMinutes = goalMinutes
            $0.defaultSessionMinutes = session
            $0.strictByDefault = profile.mascot.prefersStrictMode
            if profile.struggles.contains(.breaks) { $0.breakMinutes = 10 }
        }
        model.updateProfile { p in
            p = profile
            p.onboardedAt = Date()
        }
        model.finishOnboarding()
    }
}

/// Back button + progress bar shown on top of most steps.
struct OnboardingHeader: View {
    let progress: Double
    let canGoBack: Bool
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .opacity(canGoBack ? 1 : 0)
            .disabled(!canGoBack)
            .accessibilityLabel("Back")

            ProgressBar(progress: progress, tint: Theme.ink, track: Theme.hairline, height: 6)
                .animation(.spring(response: 0.6, dampingFraction: 0.9), value: progress)

            Color.clear.frame(width: 36, height: 36)
        }
    }
}

/// Shared layout for onboarding pages: content scrolls, the action sits at the bottom.
struct OnboardingPage<Content: View, Footer: View>: View {
    @ViewBuilder var content: Content
    @ViewBuilder var footer: Footer

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                content
                    .padding(.horizontal, Theme.pagePadding)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 6) { footer }
                .padding(.horizontal, Theme.pagePadding)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(
                    LinearGradient(colors: [Theme.background.opacity(0), Theme.background], startPoint: .top, endPoint: .center)
                        .padding(.top, -24)
                        .ignoresSafeArea()
                )
        }
    }
}

/// The question host: a small crew member with a speech bubble.
struct HostBubble: View {
    let mascot: Mascot
    let text: String
    var mood: MascotMood = .idle

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            MascotView(mascot: mascot, mood: mood, size: 78, showDecoration: false)
            SpeechBubble(text: text, tailEdge: .leading, font: .rounded(.subheadline, weight: .semibold))
            Spacer(minLength: 0)
        }
    }
}
