import FamilyControls
import SwiftUI

/// The Focus tab: companion, session setup and today's progress.
struct FocusHomeView: View {
    @Environment(AppModel.self) private var model

    @State private var minutes: Int = 25
    @State private var intention = ""
    @State private var strict = false
    @State private var block = true
    @State private var pickerShown = false
    @State private var selection = FamilyActivitySelection()
    @State private var showSettings = false
    @State private var greetingSeed = Int.random(in: 0..<100)
    @State private var didLoadDefaults = false
    @FocusState private var intentionFocused: Bool

    private let presets = [15, 25, 45, 60, 90]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    hero
                    if model.active != nil {
                        activeBanner
                    } else {
                        sessionSetup
                    }
                    todayCard
                    if let next = model.nextSchedule {
                        nextScheduleCard(next.schedule, startsAt: next.startsAt)
                    }
                }
                .padding(.horizontal, Theme.pagePadding)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .pageBackground(model.mascot.wash)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environment(model)
            }
            .familyActivityPicker(isPresented: $pickerShown, selection: $selection)
            .onChange(of: selection) { _, newValue in
                model.screenTime.setFocusSelection(newValue)
            }
            .onAppear(perform: loadDefaults)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.greeting + ",")
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
                Text(model.profile.firstName)
                    .font(.rounded(.largeTitle, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer()
            StreakPill(streak: model.streak)
            CircleIconButton(symbol: "gearshape.fill", size: 42, label: "Settings") { showSettings = true }
        }
        .padding(.top, 8)
    }

    // MARK: Hero

    private var hero: some View {
        let m = model.mascot
        return VStack(spacing: 0) {
            SpeechBubble(text: model.active != nil ? m.line(from: m.encouragements, seed: greetingSeed) : m.line(from: m.greetings, seed: greetingSeed), tailEdge: .bottom)
                .padding(.horizontal, 24)
                .onTapGesture {
                    Haptics.tap()
                    withAnimation(.spring) { greetingSeed += 1 }
                }
            MascotView(mascot: m, mood: model.active != nil ? .focused : .idle, size: 220, motion: .float)
                .padding(.top, 2)
                .onTapGesture {
                    Haptics.soft()
                    withAnimation(.spring) { greetingSeed += 1 }
                }
            HStack(spacing: 8) {
                Text(m.name)
                    .font(.rounded(.title3, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                TraitChip(title: "Lv \(model.stats.bond(with: m).level)", symbol: "heart.fill", tint: m.accent, background: Theme.surface)
            }
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(m.tint.opacity(0.55))
        )
    }

    // MARK: Session setup

    private var sessionSetup: some View {
        VStack(spacing: 14) {
            VStack(spacing: 16) {
                HStack {
                    Text("Session length")
                        .font(.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(Theme.inkSecondary)
                    Spacer()
                    Text("Ends at \(Date().addingTimeInterval(TimeInterval(minutes * 60)).formatted(date: .omitted, time: .shortened))")
                        .font(.rounded(.footnote, weight: .semibold))
                        .foregroundStyle(Theme.inkTertiary)
                }
                HStack {
                    CircleIconButton(symbol: "minus", size: 48, label: "Shorter") { adjust(-5) }
                    Spacer()
                    VStack(spacing: 0) {
                        Text("\(minutes)")
                            .font(.rounded(size: 60, weight: .heavy))
                            .foregroundStyle(Theme.ink)
                            .contentTransition(.numericText(value: Double(minutes)))
                            .monospacedDigit()
                        Text("minutes")
                            .font(.rounded(.subheadline, weight: .semibold))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    Spacer()
                    CircleIconButton(symbol: "plus", size: 48, label: "Longer") { adjust(5) }
                }
                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { p in
                        Button {
                            Haptics.select()
                            withAnimation(.spring(response: 0.3)) { minutes = p }
                        } label: {
                            Text("\(p)")
                                .font(.rounded(.subheadline, weight: .bold))
                                .foregroundStyle(minutes == p ? Theme.inkInverse : Theme.ink)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(Capsule().fill(minutes == p ? Theme.ink : Theme.surfaceMuted))
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
            .cardStyle(padding: 18, radius: Theme.cornerLarge)

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    IconBadge(symbol: "pencil", tint: model.mascot.accent, background: model.mascot.tint.opacity(0.6))
                    TextField("What will you work on?", text: $intention)
                        .font(.rounded(.body, weight: .medium))
                        .submitLabel(.done)
                        .focused($intentionFocused)
                }
                .padding(.vertical, 10)
                Divider().padding(.leading, 48)
                Button {
                    if model.screenTime.isAuthorized {
                        selection = model.screenTime.focusSelection
                        pickerShown = true
                    } else {
                        Task { await model.screenTime.requestAuthorization() }
                    }
                } label: {
                    HStack(spacing: 12) {
                        IconBadge(symbol: "lock.shield.fill", tint: model.mascot.accent, background: model.mascot.tint.opacity(0.6))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Block list")
                                .font(.rounded(.body, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                            Text(blockListSubtitle)
                                .font(.rounded(.footnote, weight: .medium))
                                .foregroundStyle(Theme.inkSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: $block)
                            .labelsHidden()
                            .tint(model.mascot.accent)
                            .disabled(!model.screenTime.isAuthorized)
                    }
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 48)
                HStack(spacing: 12) {
                    IconBadge(symbol: "hand.raised.fill", tint: model.mascot.accent, background: model.mascot.tint.opacity(0.6))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Strict mode")
                            .font(.rounded(.body, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("No pausing, and ending early takes effort")
                            .font(.rounded(.footnote, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    Spacer()
                    Toggle("", isOn: $strict)
                        .labelsHidden()
                        .tint(model.mascot.accent)
                }
                .padding(.vertical, 10)
                Divider().padding(.leading, 48)
                SoundMenuRow()
                    .padding(.vertical, 10)
            }
            .padding(.horizontal, 14)
            .cardStyle(padding: 4, radius: Theme.cornerLarge)

            Button {
                intentionFocused = false
                model.startFocus(minutes: minutes, intention: intention, strict: strict, block: block)
                intention = ""
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text("Start focusing")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 4)
        }
    }

    private var blockListSubtitle: String {
        guard model.screenTime.isAuthorized else { return "Tap to connect Screen Time" }
        let s = model.screenTime.focusSelection
        return s.isEmptySelection ? "Tap to choose apps" : s.summary
    }

    private var activeBanner: some View {
        Button { model.showSession = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "timer")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(model.mascot.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Session in progress")
                        .font(.rounded(.headline, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Tap to return to your timer")
                        .font(.rounded(.subheadline, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkTertiary)
            }
            .cardStyle(radius: Theme.cornerLarge)
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: Today

    private var todayCard: some View {
        let goal = model.settings.dailyGoalMinutes
        let today = model.todaySeconds
        let progress = goal > 0 ? Double(today) / Double(goal * 60) : 0
        let sessions = model.stats.sessions(on: Date()).filter(\.completed).count
        return HStack(spacing: 18) {
            ZStack {
                ProgressRing(progress: progress, lineWidth: 11, tint: model.mascot.accent, track: model.mascot.tint.opacity(0.6))
                VStack(spacing: 0) {
                    Text("\(Int(min(1, progress) * 100))%")
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Text("of goal")
                        .font(.rounded(.caption2, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .frame(width: 86, height: 86)
            VStack(alignment: .leading, spacing: 6) {
                Text("Today")
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(Theme.inkSecondary)
                Text("\(Format.duration(seconds: today)) of \(Format.duration(minutes: goal))")
                    .font(.rounded(.title3, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 14) {
                    Label("\(sessions) session\(sessions == 1 ? "" : "s")", systemImage: "checkmark.circle.fill")
                    Label("\(model.streak) day streak", systemImage: "flame.fill")
                }
                .font(.rounded(.caption, weight: .semibold))
                .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .cardStyle(radius: Theme.cornerLarge)
    }

    private func nextScheduleCard(_ s: BlockSchedule, startsAt: Date) -> some View {
        Button { model.selectedTab = .blocks } label: {
            HStack(spacing: 12) {
                IconBadge(symbol: s.symbol, tint: s.mascot.accent, background: s.mascot.tint.opacity(0.7), size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.name)
                        .font(.rounded(.headline, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Starts \(startsAt.formatted(.relative(presentation: .named))) · \(s.timeRangeText)")
                        .font(.rounded(.footnote, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer()
                MascotAvatar(mascot: s.mascot, size: 34)
            }
            .cardStyle(radius: Theme.cornerLarge)
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: Helpers

    private func adjust(_ delta: Int) {
        let next = min(180, max(5, minutes + delta))
        guard next != minutes else { return }
        withAnimation(.spring(response: 0.3)) { minutes = next }
    }

    private func loadDefaults() {
        guard !didLoadDefaults else { return }
        didLoadDefaults = true
        minutes = model.settings.defaultSessionMinutes
        strict = model.settings.strictByDefault
        block = model.settings.blockDuringFocus
        selection = model.screenTime.focusSelection
    }
}

struct StreakPill: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundStyle(streak > 0 ? Theme.flame : Theme.inkTertiary)
            Text("\(streak)")
                .font(.rounded(.headline, weight: .heavy))
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText(value: Double(streak)))
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(Capsule().fill(Theme.surface))
        .overlay(Capsule().strokeBorder(Theme.hairline))
        .accessibilityLabel("\(streak) day streak")
    }
}

/// Ambient sound picker row.
struct SoundMenuRow: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(symbol: model.settings.ambientSound.symbol, tint: model.mascot.accent, background: model.mascot.tint.opacity(0.6))
            Text("Focus sound")
                .font(.rounded(.body, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Menu {
                Picker("Focus sound", selection: Binding(
                    get: { model.settings.ambientSound },
                    set: { value in model.updateSettings { $0.ambientSound = value } }
                )) {
                    ForEach(AmbientSound.allCases) { s in
                        Label(s.title, systemImage: s.symbol).tag(s)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(model.settings.ambientSound.title)
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 11, weight: .bold))
                }
                .font(.rounded(.subheadline, weight: .semibold))
                .foregroundStyle(Theme.inkSecondary)
            }
        }
    }
}
