import FamilyControls
import SwiftUI

/// The Blocks tab: focus block list and recurring schedules.
struct BlocksView: View {
    @Environment(AppModel.self) private var model

    @State private var editing: BlockSchedule?
    @State private var showTemplates = false
    @State private var pickerShown = false
    @State private var selection = FamilyActivitySelection()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if !model.screenTime.isAuthorized {
                        connectCard
                    }
                    if let active = model.activeSchedule {
                        activeNowCard(active)
                    }
                    focusListCard
                    SectionHeader(title: "Schedules", trailing: "Add", action: { showTemplates = true })
                        .padding(.top, 6)
                    if model.schedules.isEmpty {
                        emptySchedules
                    } else {
                        VStack(spacing: 12) {
                            ForEach(model.schedules) { schedule in
                                ScheduleCard(schedule: schedule) {
                                    editing = schedule
                                }
                            }
                        }
                    }
                    tipCard
                }
                .padding(.horizontal, Theme.pagePadding)
                .padding(.bottom, 32)
            }
            .pageBackground()
            .navigationTitle("Blocks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showTemplates = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .accessibilityLabel("Add schedule")
                }
            }
            .sheet(item: $editing) { schedule in
                ScheduleEditorView(schedule: schedule, isNew: !model.schedules.contains { $0.id == schedule.id })
                    .environment(model)
            }
            .sheet(isPresented: $showTemplates) {
                ScheduleTemplatesSheet { template in
                    showTemplates = false
                    var s = template
                    s.id = UUID()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { editing = s }
                }
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(32)
            }
            .familyActivityPicker(isPresented: $pickerShown, selection: $selection)
            .onChange(of: pickerShown) { _, shown in
                if !shown { model.screenTime.setFocusSelection(selection) }
            }
        }
    }

    private var connectCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                MascotView(mascot: .pebble, mood: .focused, size: 84, showDecoration: false, motion: .breathe)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connect Screen Time")
                        .font(.rounded(.headline, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Pebble needs Apple's permission to block apps. Your data stays on this iPhone.")
                        .font(.rounded(.footnote, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Button("Connect") {
                Task { await model.screenTime.requestAuthorization() }
            }
            .buttonStyle(PrimaryButtonStyle())
            if let error = model.screenTime.lastError {
                Text(error)
                    .font(.rounded(.footnote, weight: .semibold))
                    .foregroundStyle(Theme.warning)
            }
        }
        .cardStyle(radius: Theme.cornerLarge)
    }

    private func activeNowCard(_ s: BlockSchedule) -> some View {
        HStack(spacing: 12) {
            MascotView(mascot: s.mascot, mood: .focused, size: 64, showDecoration: false, motion: .breathe)
            VStack(alignment: .leading, spacing: 3) {
                Text("ACTIVE NOW")
                    .font(.rounded(.caption2, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(s.mascot.accent)
                Text(s.name)
                    .font(.rounded(.headline, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("\(s.mascot.name) is guarding \(s.blockedItemCount) item\(s.blockedItemCount == 1 ? "" : "s") until \(BlockSchedule.format(s.endMinutes))")
                    .font(.rounded(.footnote, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous).fill(s.mascot.tint.opacity(0.6)))
    }

    private var focusListCard: some View {
        let s = model.screenTime.focusSelection
        return Button {
            guard model.screenTime.isAuthorized else {
                Task { await model.screenTime.requestAuthorization() }
                return
            }
            selection = s
            pickerShown = true
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    IconBadge(symbol: "scope", tint: model.mascot.accent, background: model.mascot.tint.opacity(0.6), size: 42)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Focus block list")
                            .font(.rounded(.headline, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Text("Blocked during every focus session")
                            .font(.rounded(.footnote, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    Spacer()
                    Text("Edit")
                        .font(.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(model.mascot.accent)
                }
                if s.isEmptySelection {
                    Text("Nothing yet. Tap to choose apps, categories or websites.")
                        .font(.rounded(.subheadline, weight: .medium))
                        .foregroundStyle(Theme.inkTertiary)
                } else {
                    HStack {
                        BlockedAppsPreview(selection: s, limit: 6)
                        Spacer()
                        Text(s.summary)
                            .font(.rounded(.footnote, weight: .semibold))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
            }
            .cardStyle(radius: Theme.cornerLarge)
        }
        .buttonStyle(PressableStyle())
    }

    private var emptySchedules: some View {
        VStack(spacing: 10) {
            MascotView(mascot: .leaf, mood: .sleepy, size: 120, motion: .breathe)
            Text("No schedules yet")
                .font(.rounded(.headline, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text("Block apps automatically during work, study or bedtime. No timer needed.")
                .font(.rounded(.subheadline, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
            Button("Create a schedule") { showTemplates = true }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .cardStyle(padding: 20, radius: Theme.cornerLarge)
    }

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 12) {
            MascotAvatar(mascot: .blob, size: 36)
            Text("Tip: schedules keep working even when Focus Crew is closed. Blocked apps show a reminder from your crew.")
                .font(.rounded(.footnote, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }
}

/// One schedule in the list.
struct ScheduleCard: View {
    @Environment(AppModel.self) private var model
    let schedule: BlockSchedule
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    IconBadge(symbol: schedule.symbol, tint: schedule.mascot.accent, background: schedule.mascot.tint.opacity(0.7), size: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(schedule.name)
                                .font(.rounded(.headline, weight: .bold))
                                .foregroundStyle(Theme.ink)
                            if schedule.isActive() {
                                Text("ON NOW")
                                    .font(.rounded(.caption2, weight: .heavy))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Capsule().fill(Theme.success))
                            }
                        }
                        Text(schedule.timeRangeText)
                            .font(.rounded(.subheadline, weight: .semibold))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { schedule.isEnabled },
                        set: { model.toggle(schedule: schedule, on: $0) }
                    ))
                    .labelsHidden()
                    .tint(schedule.mascot.accent)
                }
                HStack {
                    WeekdayDots(selected: schedule.weekdays, tint: schedule.mascot.accent)
                    Spacer()
                    Label(schedule.blockedItemCount == 0 ? "No apps" : "\(schedule.blockedItemCount) blocked", systemImage: "lock.fill")
                        .font(.rounded(.caption, weight: .semibold))
                        .foregroundStyle(schedule.blockedItemCount == 0 ? Theme.warning : Theme.inkSecondary)
                }
            }
            .cardStyle(radius: Theme.cornerLarge)
            .opacity(schedule.isEnabled ? 1 : 0.6)
        }
        .buttonStyle(PressableStyle())
    }
}

/// Quick-start templates for new schedules.
struct ScheduleTemplatesSheet: View {
    let onPick: (BlockSchedule) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(BlockSchedule.templates) { t in
                        Button { onPick(t) } label: {
                            HStack(spacing: 12) {
                                IconBadge(symbol: t.symbol, tint: t.mascot.accent, background: t.mascot.tint.opacity(0.7), size: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(t.name).font(.rounded(.headline, weight: .bold)).foregroundStyle(Theme.ink)
                                    Text("\(t.timeRangeText) · \(t.daysText)").font(.rounded(.footnote, weight: .medium)).foregroundStyle(Theme.inkSecondary)
                                }
                                Spacer()
                                MascotAvatar(mascot: t.mascot, size: 32)
                            }
                            .cardStyle(padding: 14)
                        }
                        .buttonStyle(PressableStyle())
                    }
                    Button {
                        onPick(BlockSchedule(name: "My schedule", symbol: "clock.fill", startMinutes: 9 * 60, endMinutes: 12 * 60, weekdays: [2, 3, 4, 5, 6], mascot: .orbit))
                    } label: {
                        HStack(spacing: 12) {
                            IconBadge(symbol: "plus", tint: Theme.inkInverse, background: Theme.ink, size: 44)
                            Text("Custom schedule").font(.rounded(.headline, weight: .bold)).foregroundStyle(Theme.ink)
                            Spacer()
                        }
                        .cardStyle(padding: 14)
                    }
                    .buttonStyle(PressableStyle())
                }
                .padding(Theme.pagePadding)
            }
            .pageBackground()
            .navigationTitle("New schedule")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
