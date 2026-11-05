import FamilyControls
import StoreKit
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview

    @State private var confirmReset = false
    @State private var retakeQuiz = false
    @State private var showMembership = false
    @State private var pickerShown = false
    @State private var selection = FamilyActivitySelection()
    @State private var showMacInfo = false
    @State private var showWidgetInfo = false

    var body: some View {
        NavigationStack {
            List {
                profileSection
                focusSection
                blockingSection
                soundSection
                notificationSection
                companionsSection
                membershipSection
                supportSection
                dangerSection
                footer
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.font(.rounded(.body, weight: .bold))
                }
            }
            .familyActivityPicker(isPresented: $pickerShown, selection: $selection)
            .onChange(of: pickerShown) { _, shown in
                if !shown { model.screenTime.setFocusSelection(selection) }
            }
            .confirmationDialog("Reset everything?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Erase all data", role: .destructive) {
                    model.resetEverything()
                    dismiss()
                }
            } message: {
                Text("This deletes your history, schedules, badges and settings and removes all app blocks. It can't be undone.")
            }
            .sheet(isPresented: $showMembership) {
                PaywallView(mascot: model.mascot, context: .settings) { showMembership = false }
                    .environment(model)
            }
            .sheet(isPresented: $showMacInfo) { MacCompanionInfoView() }
            .sheet(isPresented: $showWidgetInfo) { WidgetInfoView().environment(model) }
            .fullScreenCover(isPresented: $retakeQuiz) {
                RetakeQuizView().environment(model)
            }
        }
        .tint(model.mascot.accent)
    }

    // MARK: Sections

    private var profileSection: some View {
        Section {
            HStack(spacing: 14) {
                MascotAvatar(mascot: model.mascot, size: 56)
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Your name", text: Binding(
                        get: { model.profile.name },
                        set: { v in model.updateProfile { $0.name = v } }
                    ))
                    .font(.rounded(.title3, weight: .bold))
                    Text("Focusing with \(model.mascot.name) since \(model.profile.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.rounded(.caption, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var focusSection: some View {
        Section("Focus") {
            stepperRow("Daily goal", symbol: "target", value: model.settings.dailyGoalMinutes, range: 15...480, step: 15) { v in
                model.updateSettings { $0.dailyGoalMinutes = v }
            }
            stepperRow("Default session", symbol: "timer", value: model.settings.defaultSessionMinutes, range: 5...180, step: 5) { v in
                model.updateSettings { $0.defaultSessionMinutes = v }
            }
            stepperRow("Break length", symbol: "cup.and.saucer.fill", value: model.settings.breakMinutes, range: 1...30, step: 1) { v in
                model.updateSettings { $0.breakMinutes = v }
            }
            toggleRow("Strict mode by default", symbol: "hand.raised.fill", isOn: model.settings.strictByDefault) { v in
                model.updateSettings { $0.strictByDefault = v }
            }
            toggleRow("Allow pausing", symbol: "pause.circle.fill", isOn: model.settings.allowPauses) { v in
                model.updateSettings { $0.allowPauses = v }
            }
            toggleRow("Live Activity", symbol: "iphone.gen3.radiowaves.left.and.right", isOn: model.settings.liveActivitiesEnabled) { v in
                model.updateSettings { $0.liveActivitiesEnabled = v }
            }
        }
    }

    private var blockingSection: some View {
        Section {
            HStack {
                rowLabel("Screen Time", symbol: "hourglass")
                Spacer()
                if model.screenTime.isAuthorized {
                    Label(model.screenTime.statusText, systemImage: "checkmark.circle.fill")
                        .font(.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(Theme.success)
                } else {
                    Button("Connect") { Task { await model.screenTime.requestAuthorization() } }
                        .font(.rounded(.subheadline, weight: .bold))
                }
            }
            Button {
                selection = model.screenTime.focusSelection
                pickerShown = true
            } label: {
                HStack {
                    rowLabel("Focus block list", symbol: "lock.shield.fill")
                    Spacer()
                    Text(model.screenTime.focusSelection.summary)
                        .font(.rounded(.subheadline))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .disabled(!model.screenTime.isAuthorized)
            toggleRow("Block apps during focus", symbol: "lock.fill", isOn: model.settings.blockDuringFocus) { v in
                model.updateSettings { $0.blockDuringFocus = v }
            }
        } header: {
            Text("Blocking")
        } footer: {
            Text("Focus Crew uses Apple's Screen Time API. Your app usage stays on this device and is never sent to us.")
        }
    }

    private var soundSection: some View {
        Section("Sound & haptics") {
            Picker(selection: Binding(
                get: { model.settings.ambientSound },
                set: { v in model.updateSettings { $0.ambientSound = v } }
            )) {
                ForEach(AmbientSound.allCases) { s in Text(s.title).tag(s) }
            } label: {
                rowLabel("Focus sound", symbol: "waveform")
            }
            HStack {
                rowLabel("Volume", symbol: "speaker.wave.2.fill")
                Slider(value: Binding(
                    get: { model.settings.ambientVolume },
                    set: { v in model.updateSettings { $0.ambientVolume = v } }
                ), in: 0...1)
            }
            toggleRow("Completion chime", symbol: "bell.fill", isOn: model.settings.chimeEnabled) { v in
                model.updateSettings { $0.chimeEnabled = v }
            }
            toggleRow("Haptics", symbol: "hand.tap.fill", isOn: model.settings.hapticsEnabled) { v in
                model.updateSettings { $0.hapticsEnabled = v }
            }
            Picker(selection: Binding(
                get: { model.settings.appearance },
                set: { v in model.updateSettings { $0.appearance = v } }
            )) {
                ForEach(AppearancePreference.allCases) { a in Text(a.title).tag(a) }
            } label: {
                rowLabel("Appearance", symbol: "circle.lefthalf.filled")
            }
        }
    }

    private var notificationSection: some View {
        Section("Notifications") {
            toggleRow("Session alerts", symbol: "bell.badge.fill", isOn: model.settings.sessionEndAlerts) { v in
                model.updateSettings { $0.sessionEndAlerts = v }
            }
            toggleRow("Daily reminder", symbol: "alarm.fill", isOn: model.settings.dailyReminderEnabled) { v in
                if v { Task { await Notifications.requestAuthorization() } }
                model.updateSettings { $0.dailyReminderEnabled = v }
            }
            if model.settings.dailyReminderEnabled {
                DatePicker(selection: Binding(
                    get: { ScheduleEditorView.date(from: model.settings.dailyReminderMinutes) },
                    set: { d in
                        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                        model.updateSettings { $0.dailyReminderMinutes = (c.hour ?? 9) * 60 + (c.minute ?? 0) }
                    }
                ), displayedComponents: .hourAndMinute) {
                    rowLabel("Remind me at", symbol: "clock.fill")
                }
            }
            toggleRow("Streak saver", symbol: "flame.fill", isOn: model.settings.streakReminderEnabled) { v in
                model.updateSettings { $0.streakReminderEnabled = v }
            }
        }
    }

    private var companionsSection: some View {
        Section("Companions") {
            Button { showMacInfo = true } label: {
                HStack {
                    rowLabel("Mac notch companion", symbol: "laptopcomputer")
                    Spacer()
                    Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Theme.inkTertiary)
                }
            }
            toggleRow("Sync sessions to Mac", symbol: "icloud.fill", isOn: model.settings.syncToMac) { v in
                model.updateSettings { $0.syncToMac = v }
            }
            Button { showWidgetInfo = true } label: {
                HStack {
                    rowLabel("Widgets & Lock Screen", symbol: "square.grid.2x2.fill")
                    Spacer()
                    Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Theme.inkTertiary)
                }
            }
            Button { retakeQuiz = true } label: {
                rowLabel("Retake the companion quiz", symbol: "questionmark.bubble.fill")
            }
        }
    }

    private var membershipSection: some View {
        Section {
            Button { showMembership = true } label: {
                HStack(spacing: 12) {
                    IconBadge(symbol: "gift.fill", tint: model.mascot.accent, background: model.mascot.tint, size: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Monetization.paywallEnabled && !model.purchases.hasPlus ? "Focus Crew Plus" : "Early access: everything free")
                            .font(.rounded(.body, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Text(Monetization.paywallEnabled && !model.purchases.hasPlus ? "Unlock every feature" : "All features are unlocked")
                            .font(.rounded(.caption, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
            }
            if Monetization.paywallEnabled {
                Button("Restore purchases") { Task { await model.purchases.restore() } }
            }
        } header: {
            Text("Membership")
        }
    }

    private var supportSection: some View {
        Section("Support") {
            Button { requestReview() } label: { rowLabel("Rate Focus Crew", symbol: "star.fill") }
            ShareLink(item: URL(string: "https://tomasbeja2007.github.io/focus-mascots/")!, message: Text("I'm focusing with Focus Crew! Come join me.")) {
                rowLabel("Share with a friend", symbol: "square.and.arrow.up.fill")
            }
            Button { openURL(Monetization.supportURL) } label: { rowLabel("Help & support", symbol: "questionmark.circle.fill") }
            if let mail = URL(string: "mailto:\(Monetization.supportEmail)?subject=Focus%20Crew%20feedback") {
                Button { openURL(mail) } label: { rowLabel("Send feedback", symbol: "envelope.fill") }
            }
            Button { openURL(Monetization.privacyURL) } label: { rowLabel("Privacy policy", symbol: "hand.raised.square.fill") }
            Button { openURL(Monetization.termsURL) } label: { rowLabel("Terms of use", symbol: "doc.text.fill") }
        }
    }

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) { confirmReset = true } label: {
                Label("Reset all data", systemImage: "trash.fill")
                    .font(.rounded(.body, weight: .semibold))
                    .foregroundStyle(Theme.danger)
            }
        }
    }

    private var footer: some View {
        Section {
            VStack(spacing: 10) {
                HStack(spacing: -10) {
                    ForEach(Mascot.allCases) { m in MascotAvatar(mascot: m, size: 34, ring: Theme.background) }
                }
                Text("Focus Crew \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"))")
                    .font(.rounded(.caption, weight: .semibold))
                    .foregroundStyle(Theme.inkTertiary)
                Text("Made with care for your attention.")
                    .font(.rounded(.caption2))
                    .foregroundStyle(Theme.inkTertiary)
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
    }

    // MARK: Rows

    private func rowLabel(_ title: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            IconBadge(symbol: symbol, tint: model.mascot.accent, background: model.mascot.tint.opacity(0.6), size: 30)
            Text(title)
                .font(.rounded(.body, weight: .medium))
                .foregroundStyle(Theme.ink)
        }
    }

    private func toggleRow(_ title: String, symbol: String, isOn: Bool, set: @escaping (Bool) -> Void) -> some View {
        Toggle(isOn: Binding(get: { isOn }, set: set)) {
            rowLabel(title, symbol: symbol)
        }
    }

    private func stepperRow(_ title: String, symbol: String, value: Int, range: ClosedRange<Int>, step: Int, set: @escaping (Int) -> Void) -> some View {
        Stepper(value: Binding(get: { value }, set: set), in: range, step: step) {
            HStack {
                rowLabel(title, symbol: symbol)
                Spacer()
                Text(Format.longDuration(minutes: value))
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
    }
}

/// Explains the macOS notch companion.
struct MacCompanionInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    NotchMockup()
                        .frame(maxWidth: .infinity)
                    Text("Your crew, next to the notch")
                        .font(.rounded(.title, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Install Focus Crew for Mac and your companion appears right beside your MacBook's notch whenever you're focusing on your iPhone, with a live countdown. Click it to pause or end, or start a focus session right from the menu bar.")
                        .font(.rounded(.body, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                    VStack(alignment: .leading, spacing: 12) {
                        step(1, "Install Focus Crew on your Mac and open it.")
                        step(2, "Sign in to the same iCloud account on both devices.")
                        step(3, "Start a session on your iPhone. Your companion shows up by the notch.")
                    }
                    .cardStyle()
                    Text("No notch? The companion floats at the top of your screen instead.")
                        .font(.rounded(.footnote))
                        .foregroundStyle(Theme.inkTertiary)
                }
                .padding(Theme.pagePadding)
            }
            .pageBackground()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(n)")
                .font(.rounded(.subheadline, weight: .heavy))
                .foregroundStyle(Theme.inkInverse)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Theme.ink))
            Text(text)
                .font(.rounded(.body, weight: .medium))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A drawing of the Mac notch indicator.
struct NotchMockup: View {
    var mascot: Mascot = .orbit

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.55, green: 0.66, blue: 0.86), Color(red: 0.78, green: 0.72, blue: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 170)
            Rectangle().fill(.black.opacity(0.18)).frame(height: 22)
            HStack(spacing: 0) {
                MascotAvatar(mascot: mascot, size: 22)
                    .padding(.leading, 10)
                Spacer()
                Text("18:42")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .padding(.trailing, 12)
            }
            .frame(width: 230, height: 30)
            .background(UnevenRoundedRectangle(bottomLeadingRadius: 12, bottomTrailingRadius: 12, style: .continuous).fill(.black))
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// How to add widgets and Lock Screen widgets.
struct WidgetInfoView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    WidgetGallery(snapshot: model.makeSnapshot())
                    Text("Put your crew on your Home Screen")
                        .font(.rounded(.title2, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Touch and hold an empty spot on your Home Screen.", systemImage: "hand.tap.fill")
                        Label("Tap Edit, then Add Widget, and search for Focus Crew.", systemImage: "plus.circle.fill")
                        Label("For the Lock Screen, touch and hold it, tap Customize, then add a widget.", systemImage: "lock.fill")
                        Label("Add the Start Focus control to Control Center for one-tap sessions.", systemImage: "switch.2")
                    }
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .cardStyle()
                }
                .padding(Theme.pagePadding)
            }
            .pageBackground()
            .navigationTitle("Widgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

/// Re-runs the questions and lets the user switch companion.
struct RetakeQuizView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        RetakeFlow(initial: model.profile) { profile in
            let picked = profile.mascot
            model.updateProfile {
                $0.age = profile.age
                $0.role = profile.role
                $0.dailyScreenHours = profile.dailyScreenHours
                $0.struggles = profile.struggles
                $0.timeSinks = profile.timeSinks
                $0.hardestTimes = profile.hardestTimes
                $0.focusSpan = profile.focusSpan
                $0.goal = profile.goal
                $0.motivation = profile.motivation
                $0.matchedMascot = profile.matchedMascot
            }
            model.choose(mascot: picked)
            dismiss()
        } onCancel: {
            dismiss()
        }
    }
}

private struct RetakeFlow: View {
    @State private var draft: UserProfile
    @State private var index = 0
    @State private var result: MascotMatcher.Result?
    let onDone: (UserProfile) -> Void
    let onCancel: () -> Void

    init(initial: UserProfile, onDone: @escaping (UserProfile) -> Void, onCancel: @escaping () -> Void) {
        _draft = State(initialValue: initial)
        self.onDone = onDone
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(progress: Double(index) / Double(OnboardingStep.questions.count), canGoBack: true) {
                if index == 0 { onCancel() } else { withAnimation(.spring) { index -= 1 } }
            }
            .padding(.horizontal, Theme.pagePadding)
            .padding(.top, 8)
            Group {
                if index < OnboardingStep.questions.count {
                    question(OnboardingStep.questions[index])
                } else if let result {
                    MascotRevealStep(profile: $draft) { onDone(draft) }
                        .id(result.mascot)
                } else {
                    Color.clear
                }
            }
            .id(index)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
        }
        .pageBackground()
        .animation(.spring(response: 0.5, dampingFraction: 0.86), value: index)
    }

    private func next() {
        if index + 1 >= OnboardingStep.questions.count {
            let r = MascotMatcher.match(draft)
            draft.matchedMascot = r.mascot
            draft.mascot = r.mascot
            result = r
        }
        withAnimation(.spring) { index += 1 }
    }

    @ViewBuilder
    private func question(_ step: OnboardingStep) -> some View {
        switch step {
        case .age:
            SingleChoiceStep(step: step, title: "How old are you?", subtitle: "This helps us tailor your plan.", options: AgeRange.allCases, selection: $draft.age, onNext: next)
        case .role:
            SingleChoiceStep(step: step, title: "What best describes you?", subtitle: "We'll suggest sessions that fit your days.", options: LifeRole.allCases, selection: $draft.role, onNext: next)
        case .screenTime:
            ScreenTimeEstimateStep(hours: $draft.dailyScreenHours, onNext: next)
        case .struggles:
            MultiChoiceStep(step: step, title: "What do you struggle with most?", subtitle: "Pick everything that sounds like you.", options: Struggle.allCases, selection: $draft.struggles, onNext: next)
        case .timeSinks:
            MultiChoiceStep(step: step, title: "Where does your time disappear?", subtitle: "Pick all that apply.", options: TimeSink.allCases, selection: $draft.timeSinks, onNext: next)
        case .hardestTimes:
            MultiChoiceStep(step: step, title: "When is it hardest to put your phone down?", subtitle: "Pick all that apply.", options: DayPart.allCases, selection: $draft.hardestTimes, onNext: next)
        case .focusSpan:
            SingleChoiceStep(step: step, title: "How long can you focus before reaching for your phone?", subtitle: "Be honest, there's no wrong answer.", options: FocusSpan.allCases, selection: $draft.focusSpan, onNext: next)
        case .goal:
            SingleChoiceStep(step: step, title: "What's your main goal?", subtitle: "Your crew will cheer you on towards it.", options: MainGoal.allCases, selection: $draft.goal, onNext: next)
        default:
            SingleChoiceStep(step: .motivation, title: "How do you like to be motivated?", subtitle: "This decides who joins you.", options: MotivationStyle.allCases, selection: $draft.motivation, onNext: next)
        }
    }
}
