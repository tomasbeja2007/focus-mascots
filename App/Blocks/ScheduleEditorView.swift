import FamilyControls
import SwiftUI

struct ScheduleEditorView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var schedule: BlockSchedule
    @State private var selection: FamilyActivitySelection
    @State private var start: Date
    @State private var end: Date
    @State private var pickerShown = false
    @State private var confirmDelete = false
    let isNew: Bool

    private let symbols = ["briefcase.fill", "book.fill", "moon.stars.fill", "sunrise.fill", "fork.knife", "figure.run", "brain.head.profile", "house.fill", "graduationcap.fill", "heart.fill", "car.fill", "clock.fill"]

    init(schedule: BlockSchedule, isNew: Bool) {
        self.isNew = isNew
        _schedule = State(initialValue: schedule)
        _selection = State(initialValue: SelectionStore.decode(schedule.selectionData) ?? FamilyActivitySelection())
        _start = State(initialValue: ScheduleEditorView.date(from: schedule.startMinutes))
        _end = State(initialValue: ScheduleEditorView.date(from: schedule.endMinutes))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Spacer()
                        MascotView(mascot: schedule.mascot, mood: .focused, size: 130, motion: .breathe)
                        Spacer()
                    }

                    // Name + icon
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Schedule name", text: $schedule.name)
                            .font(.rounded(.title3, weight: .bold))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(symbols, id: \.self) { sym in
                                    Button {
                                        Haptics.select()
                                        schedule.symbol = sym
                                    } label: {
                                        IconBadge(
                                            symbol: sym,
                                            tint: schedule.symbol == sym ? Theme.inkInverse : Theme.ink,
                                            background: schedule.symbol == sym ? Theme.ink : Theme.surfaceMuted,
                                            size: 40
                                        )
                                    }
                                    .buttonStyle(PressableStyle())
                                }
                            }
                        }
                    }
                    .cardStyle(radius: Theme.cornerLarge)

                    // Time
                    VStack(spacing: 0) {
                        timeRow("Starts", selection: $start, symbol: "play.circle.fill")
                        Divider().padding(.leading, 48)
                        timeRow("Ends", selection: $end, symbol: "stop.circle.fill")
                        if minutes(of: end) <= minutes(of: start) {
                            Text("Ends the next morning")
                                .font(.rounded(.caption, weight: .semibold))
                                .foregroundStyle(Theme.inkSecondary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.bottom, 8)
                        }
                    }
                    .padding(.horizontal, 14)
                    .cardStyle(padding: 4, radius: Theme.cornerLarge)

                    // Days
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Repeat on")
                            .font(.rounded(.subheadline, weight: .bold))
                            .foregroundStyle(Theme.inkSecondary)
                        HStack(spacing: 6) {
                            ForEach([2, 3, 4, 5, 6, 7, 1], id: \.self) { day in
                                let on = schedule.weekdays.contains(day)
                                Button {
                                    Haptics.select()
                                    if on { schedule.weekdays.removeAll { $0 == day } } else { schedule.weekdays.append(day) }
                                } label: {
                                    Text(Calendar.current.veryShortWeekdaySymbols[day - 1])
                                        .font(.rounded(.subheadline, weight: .bold))
                                        .foregroundStyle(on ? Theme.inkInverse : Theme.ink)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background(Circle().fill(on ? schedule.mascot.accent : Theme.surfaceMuted))
                                }
                                .buttonStyle(PressableStyle())
                            }
                        }
                        HStack(spacing: 8) {
                            quickDays("Weekdays", [2, 3, 4, 5, 6])
                            quickDays("Weekends", [1, 7])
                            quickDays("Every day", [1, 2, 3, 4, 5, 6, 7])
                        }
                    }
                    .cardStyle(radius: Theme.cornerLarge)

                    // Apps
                    Button {
                        if model.screenTime.isAuthorized {
                            pickerShown = true
                        } else {
                            Task { await model.screenTime.requestAuthorization() }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            IconBadge(symbol: "lock.shield.fill", tint: schedule.mascot.accent, background: schedule.mascot.tint.opacity(0.7), size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apps to block")
                                    .font(.rounded(.body, weight: .bold))
                                    .foregroundStyle(Theme.ink)
                                Text(model.screenTime.isAuthorized ? selection.summary : "Connect Screen Time first")
                                    .font(.rounded(.footnote, weight: .medium))
                                    .foregroundStyle(Theme.inkSecondary)
                            }
                            Spacer()
                            if !selection.applicationTokens.isEmpty {
                                BlockedAppsPreview(selection: selection, limit: 3)
                            }
                            Image(systemName: "chevron.right").foregroundStyle(Theme.inkTertiary)
                        }
                        .cardStyle(radius: Theme.cornerLarge)
                    }
                    .buttonStyle(PressableStyle())

                    // Guardian + strict
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Guardian")
                            .font(.rounded(.subheadline, weight: .bold))
                            .foregroundStyle(Theme.inkSecondary)
                        HStack(spacing: 6) {
                            ForEach(Mascot.allCases) { m in
                                Button {
                                    Haptics.select()
                                    schedule.mascot = m
                                } label: {
                                    MascotAvatar(mascot: m, size: 50, ring: schedule.mascot == m ? m.accent : nil)
                                        .opacity(schedule.mascot == m ? 1 : 0.55)
                                }
                                .buttonStyle(PressableStyle())
                                .frame(maxWidth: .infinity)
                            }
                        }
                        Divider()
                        Toggle(isOn: $schedule.strict) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Strict").font(.rounded(.body, weight: .bold)).foregroundStyle(Theme.ink)
                                Text("Also stops apps from being deleted while active").font(.rounded(.footnote, weight: .medium)).foregroundStyle(Theme.inkSecondary)
                            }
                        }
                        .tint(schedule.mascot.accent)
                    }
                    .cardStyle(radius: Theme.cornerLarge)

                    if !isNew {
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Text("Delete schedule")
                                .font(.rounded(.headline, weight: .bold))
                                .foregroundStyle(Theme.danger)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                }
                .padding(.horizontal, Theme.pagePadding)
                .padding(.bottom, 32)
            }
            .pageBackground()
            .navigationTitle(isNew ? "New schedule" : "Edit schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .font(.rounded(.body, weight: .bold))
                        .disabled(schedule.weekdays.isEmpty || schedule.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .familyActivityPicker(isPresented: $pickerShown, selection: $selection)
            .confirmationDialog("Delete \(schedule.name)?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    model.delete(schedule: schedule)
                    dismiss()
                }
            }
        }
    }

    private func timeRow(_ title: String, selection: Binding<Date>, symbol: String) -> some View {
        HStack(spacing: 12) {
            IconBadge(symbol: symbol, tint: schedule.mascot.accent, background: schedule.mascot.tint.opacity(0.7))
            Text(title)
                .font(.rounded(.body, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            DatePicker(title, selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
        .padding(.vertical, 10)
    }

    private func quickDays(_ title: String, _ days: [Int]) -> some View {
        Button {
            Haptics.select()
            schedule.weekdays = days
        } label: {
            Text(title)
                .font(.rounded(.caption, weight: .bold))
                .foregroundStyle(Set(schedule.weekdays) == Set(days) ? Theme.inkInverse : Theme.ink)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(Capsule().fill(Set(schedule.weekdays) == Set(days) ? Theme.ink : Theme.surfaceMuted))
        }
        .buttonStyle(PressableStyle())
    }

    private func save() {
        var s = schedule
        s.name = s.name.trimmingCharacters(in: .whitespaces)
        s.startMinutes = minutes(of: start)
        s.endMinutes = minutes(of: end)
        s.selectionData = SelectionStore.encode(selection)
        s.appCount = selection.applicationTokens.count
        s.categoryCount = selection.categoryTokens.count
        s.webCount = selection.webDomainTokens.count
        // Screen Time schedules must last at least 15 minutes.
        let length = (s.endMinutes - s.startMinutes + 24 * 60) % (24 * 60)
        if length < 15 { s.endMinutes = (s.startMinutes + 15) % (24 * 60) }
        model.save(schedule: s)
        Haptics.success()
        dismiss()
    }

    private func minutes(of date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    static func date(from minutes: Int) -> Date {
        Calendar.current.date(bySettingHour: (minutes / 60) % 24, minute: minutes % 60, second: 0, of: Date()) ?? Date()
    }
}
