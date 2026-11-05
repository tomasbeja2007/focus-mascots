import FamilyControls
import SwiftUI

/// Explains and requests Apple's Screen Time permission.
struct ScreenTimePermissionStep: View {
    @Environment(AppModel.self) private var model
    let onNext: () -> Void
    @State private var requesting = false
    @State private var failed = false

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 36, style: .continuous).fill(Mascot.pebble.wash)
                    HStack(spacing: -10) {
                        MascotView(mascot: .pebble, mood: model.screenTime.isAuthorized ? .happy : .focused, size: 200, motion: .breathe)
                        Image(systemName: model.screenTime.isAuthorized ? "checkmark.shield.fill" : "lock.shield.fill")
                            .font(.system(size: 64, weight: .semibold))
                            .foregroundStyle(model.screenTime.isAuthorized ? Theme.success : Mascot.pebble.accent)
                            .symbolEffect(.bounce, value: model.screenTime.isAuthorized)
                    }
                }
                .frame(height: 230)

                Text("Let Pebble guard your apps")
                    .font(.rounded(.largeTitle, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("Focus Crew uses Apple's Screen Time to block distracting apps while you focus. Apple shows a permission prompt next.")
                    .font(.rounded(.body, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 14) {
                    privacyRow("lock.iphone", "Private by design", "Your app usage never leaves your iPhone. Not even we can see it.")
                    privacyRow("hand.raised.fill", "You're in control", "Choose exactly what gets blocked and change it any time.")
                    privacyRow("apple.logo", "Powered by Apple", "Built on the same Screen Time technology as iOS itself.")
                }
                .cardStyle()

                if failed {
                    Label(model.screenTime.lastError ?? "Screen Time permission wasn't granted. You can connect it later in Settings.", systemImage: "exclamationmark.triangle.fill")
                        .font(.rounded(.footnote, weight: .semibold))
                        .foregroundStyle(Theme.warning)
                }
            }
        } footer: {
            if model.screenTime.isAuthorized {
                Button("Continue", action: onNext)
                    .buttonStyle(PrimaryButtonStyle())
            } else {
                Button {
                    requesting = true
                    Task {
                        let ok = await model.screenTime.requestAuthorization()
                        requesting = false
                        if ok {
                            Haptics.success()
                            try? await Task.sleep(nanoseconds: 600_000_000)
                            onNext()
                        } else {
                            failed = true
                            Haptics.warning()
                        }
                    }
                } label: {
                    if requesting { ProgressView().tint(Theme.inkInverse) } else { Text("Connect Screen Time") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(requesting)
                Button(failed ? "Continue without blocking" : "Not now", action: onNext)
                    .buttonStyle(QuietButtonStyle())
            }
        }
        .onAppear { model.screenTime.refreshStatus() }
    }

    private func privacyRow(_ symbol: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(symbol: symbol, tint: Mascot.pebble.accent, background: Mascot.pebble.tint.opacity(0.6), size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.rounded(.subheadline, weight: .bold)).foregroundStyle(Theme.ink)
                Text(text).font(.rounded(.footnote, weight: .medium)).foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Lets the user pick their distractions with Apple's app picker.
struct ChooseAppsStep: View {
    @Environment(AppModel.self) private var model
    let profile: UserProfile
    let onNext: () -> Void

    @State private var pickerShown = false
    @State private var selection = FamilyActivitySelection()

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 18) {
                HostBubble(mascot: .pebble, text: "Tell me what to guard. I don't take bribes.", mood: .focused)
                Text("Which apps distract you?")
                    .font(.rounded(.largeTitle, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("These get blocked during focus sessions. Picking whole categories like Social or Games works great.")
                    .font(.rounded(.body, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !profile.timeSinks.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Based on your answers, try blocking")
                            .font(.rounded(.subheadline, weight: .semibold))
                            .foregroundStyle(Theme.inkSecondary)
                        FlowLayout(spacing: 8) {
                            ForEach(profile.timeSinks) { sink in
                                TraitChip(title: sink.title, symbol: sink.symbol, tint: Mascot.pebble.accent, background: Theme.surface)
                            }
                        }
                    }
                }

                Button {
                    pickerShown = true
                } label: {
                    HStack(spacing: 14) {
                        IconBadge(symbol: selection.isEmptySelection ? "plus" : "checkmark", tint: Theme.inkInverse, background: Theme.ink, size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selection.isEmptySelection ? "Choose apps to block" : "Your block list")
                                .font(.rounded(.headline, weight: .bold))
                                .foregroundStyle(Theme.ink)
                            Text(selection.isEmptySelection ? "Opens Apple's app picker" : selection.summary)
                                .font(.rounded(.subheadline, weight: .medium))
                                .foregroundStyle(Theme.inkSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.inkTertiary)
                    }
                    .cardStyle(padding: 14)
                }
                .buttonStyle(PressableStyle())
                .disabled(!model.screenTime.isAuthorized)

                if !selection.applicationTokens.isEmpty {
                    BlockedAppsPreview(selection: selection)
                }

                if !model.screenTime.isAuthorized {
                    Label("Connect Screen Time first to choose apps. You can do it later from the Blocks tab.", systemImage: "info.circle.fill")
                        .font(.rounded(.footnote, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        } footer: {
            Button(selection.isEmptySelection ? "Skip for now" : "Save block list") {
                if !selection.isEmptySelection { model.screenTime.setFocusSelection(selection) }
                onNext()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .familyActivityPicker(isPresented: $pickerShown, selection: $selection)
        .onAppear { selection = model.screenTime.focusSelection }
    }
}

/// Icons of the first few blocked apps (rendered by Screen Time itself).
struct BlockedAppsPreview: View {
    let selection: FamilyActivitySelection
    var limit = 8

    var body: some View {
        let apps = Array(selection.applicationTokens.prefix(limit))
        HStack(spacing: -8) {
            ForEach(apps, id: \.self) { token in
                Label(token)
                    .labelStyle(.iconOnly)
                    .scaleEffect(1.3)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Theme.surface))
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Theme.background, lineWidth: 2))
            }
            if selection.applicationTokens.count > limit {
                Text("+\(selection.applicationTokens.count - limit)")
                    .font(.rounded(.caption, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Theme.surfaceMuted))
                    .overlay(Circle().strokeBorder(Theme.background, lineWidth: 2))
            }
        }
    }
}

struct NotificationsStep: View {
    @Environment(AppModel.self) private var model
    let mascot: Mascot
    let onNext: () -> Void
    @State private var reminderTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 36, style: .continuous).fill(Mascot.spark.wash)
                    MascotView(mascot: .spark, mood: .excited, size: 210, motion: .float)
                    NotificationPreview(mascot: mascot)
                        .padding(.horizontal, 18)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 14)
                }
                .frame(height: 280)

                Text("Want a friendly nudge?")
                    .font(.rounded(.largeTitle, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("We'll tell you when a session ends, remind you to focus and help you protect your streak. Never spam.")
                    .font(.rounded(.body, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    IconBadge(symbol: "alarm.fill", tint: Mascot.spark.accent, background: Mascot.spark.tint.opacity(0.6))
                    Text("Daily reminder")
                        .font(.rounded(.body, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    DatePicker("Daily reminder", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                .cardStyle(padding: 14)
            }
        } footer: {
            Button("Allow notifications") {
                Task {
                    let granted = await Notifications.requestAuthorization()
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                    model.updateSettings {
                        $0.dailyReminderEnabled = granted
                        $0.dailyReminderMinutes = (comps.hour ?? 9) * 60 + (comps.minute ?? 0)
                        $0.sessionEndAlerts = true
                    }
                    onNext()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            Button("Not now", action: onNext)
                .buttonStyle(QuietButtonStyle())
        }
    }
}

/// A fake iOS banner to show what notifications look like.
struct NotificationPreview: View {
    let mascot: Mascot

    var body: some View {
        HStack(spacing: 10) {
            Image("orbit_avatar")
                .resizable()
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                HStack {
                    Text("Focus Crew").font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text("now").font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Text("\(mascot.name): Session complete!").font(.system(size: 13, weight: .semibold))
                Text("You focused for 25 minutes. Take a break!").font(.system(size: 13)).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.regularMaterial))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }
}

/// Hold-to-commit pledge.
struct PledgeStep: View {
    let profile: UserProfile
    let goalMinutes: Int
    let onNext: () -> Void
    @State private var committed = false

    var body: some View {
        ZStack {
            OnboardingPage {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Make a promise to yourself")
                        .font(.rounded(.largeTitle, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("I, **\(profile.displayName)**, promise to:")
                            .font(.rounded(.title3, weight: .medium))
                            .foregroundStyle(Theme.ink)
                        pledgeLine("Protect \(Format.longDuration(minutes: goalMinutes)) of focus every day")
                        pledgeLine("Pick up my phone with intention, not habit")
                        pledgeLine("Be kind to myself when I slip up")
                        pledgeLine("Let \(profile.mascot.name) help me get there")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle(padding: 20, radius: Theme.cornerLarge)

                    HStack {
                        Spacer()
                        MascotView(mascot: profile.mascot, mood: committed ? .excited : .idle, size: 190, motion: committed ? .bounce : .breathe)
                        Spacer()
                    }
                }
            } footer: {
                if committed {
                    Button("Continue", action: onNext)
                        .buttonStyle(PrimaryButtonStyle())
                } else {
                    HoldToConfirmButton(title: "Hold to commit", holdingTitle: "Committing\u{2026}", duration: 1.6) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { committed = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { onNext() }
                    }
                    Text("Press and hold until the bar fills up")
                        .font(.rounded(.footnote))
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
            if committed {
                ConfettiView().ignoresSafeArea()
            }
        }
    }

    private func pledgeLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: committed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(committed ? profile.mascot.accent : Theme.inkTertiary)
            Text(text)
                .font(.rounded(.body, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Wrapping horizontal layout for chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
