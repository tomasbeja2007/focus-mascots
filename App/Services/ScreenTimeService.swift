import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import Observation

/// Wraps Apple's Screen Time APIs (FamilyControls, ManagedSettings, DeviceActivity).
@MainActor
@Observable
final class ScreenTimeService {
    private(set) var status: AuthorizationStatus = AuthorizationCenter.shared.authorizationStatus
    private(set) var focusSelection: FamilyActivitySelection = SelectionStore.loadFocus()
    var lastError: String?
    /// Screenshot mode only: pretend Screen Time is connected.
    var demoAuthorized = false

    var isAuthorized: Bool { demoAuthorized || status == .approved }

    var statusText: String {
        if isAuthorized { return "Connected" }
        return status == .denied ? "Not allowed" : "Not connected"
    }

    func refreshStatus() {
        status = AuthorizationCenter.shared.authorizationStatus
    }

    /// Shows Apple's Screen Time permission sheet.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            lastError = nil
        } catch {
            lastError = Self.describe(error)
        }
        refreshStatus()
        return isAuthorized
    }

    func setFocusSelection(_ selection: FamilyActivitySelection) {
        focusSelection = selection
        SelectionStore.saveFocus(selection)
    }

    // MARK: Focus sessions

    /// Shields the focus list and asks the system to lift the shields at `session.endsAt`,
    /// even if the app is suspended or killed.
    func beginFocus(_ session: ActiveSession) {
        guard isAuthorized, session.blocking else { return }
        Shields.apply(focusSelection, to: .focus, denyAppRemoval: session.strict)
        monitorFocusEnd(session.endsAt)
    }

    func liftFocusShields() {
        Shields.clear(.focus)
        DeviceActivityCenter().stopMonitoring([.focusSession])
    }

    private func monitorFocusEnd(_ end: Date) {
        let center = DeviceActivityCenter()
        center.stopMonitoring([.focusSession])

        // DeviceActivity intervals must be at least 15 minutes long. For shorter
        // sessions we stretch the interval and use the end *warning* (fired exactly
        // `warningTime` before the stretched end) to lift the shields on time.
        let now = Date()
        let minimumEnd = now.addingTimeInterval(15 * 60 + 30)
        var intervalEnd = end
        var warning: DateComponents?
        if end < minimumEnd {
            let extraMinutes = Int((minimumEnd.timeIntervalSince(end) / 60).rounded(.up))
            intervalEnd = end.addingTimeInterval(TimeInterval(extraMinutes * 60))
            warning = DateComponents(minute: extraMinutes)
        }
        let cal = Calendar.current
        let schedule = DeviceActivitySchedule(
            intervalStart: cal.dateComponents([.hour, .minute, .second], from: now),
            intervalEnd: cal.dateComponents([.hour, .minute, .second], from: intervalEnd),
            repeats: false,
            warningTime: warning
        )
        do {
            try center.startMonitoring(.focusSession, during: schedule)
        } catch {
            lastError = Self.describe(error)
        }
    }

    // MARK: Schedules

    /// Registers every enabled schedule with DeviceActivity and refreshes the shields.
    func sync(schedules: [BlockSchedule]) {
        guard isAuthorized else { return }
        let center = DeviceActivityCenter()
        let existing = center.activities.filter { $0.scheduleID != nil }
        // Note: stopMonitoring([]) would stop *everything*, so only call it with a non-empty list.
        if !existing.isEmpty { center.stopMonitoring(existing) }

        let wanted = schedules.filter { $0.isEnabled && $0.blockedItemCount > 0 }
        for schedule in wanted {
            let start = DateComponents(hour: schedule.startMinutes / 60, minute: schedule.startMinutes % 60)
            let end = DateComponents(hour: (schedule.endMinutes / 60) % 24, minute: schedule.endMinutes % 60)
            let interval = DeviceActivitySchedule(intervalStart: start, intervalEnd: end, repeats: true)
            do {
                try center.startMonitoring(.schedule(schedule.id), during: interval)
            } catch {
                lastError = Self.describe(error)
            }
            Shields.refresh(schedule: schedule)
        }
        // Clear shields of schedules that were removed or switched off.
        let wantedIDs = Set(wanted.map(\.id))
        for name in existing {
            if let id = name.scheduleID, !wantedIDs.contains(id) { Shields.clear(.schedule(id)) }
        }
        for schedule in schedules where !wantedIDs.contains(schedule.id) {
            Shields.clear(.schedule(schedule.id))
        }
    }

    func removeAllBlocking() {
        Shields.clear(.focus)
        for name in DeviceActivityCenter().activities {
            if let id = name.scheduleID { Shields.clear(.schedule(id)) }
        }
        DeviceActivityCenter().stopMonitoring()
    }

    static func describe(_ error: Error) -> String {
        if let fc = error as? FamilyControlsError {
            switch fc {
            case .restricted: return "Screen Time is restricted on this device."
            case .unavailable: return "Screen Time isn't available right now. Make sure you're signed in to iCloud."
            case .invalidAccountType: return "Screen Time needs an iCloud account that isn't managed by someone else."
            case .authorizationConflict: return "Another app is already managing Screen Time on this device."
            case .authorizationCanceled: return "You cancelled the Screen Time permission."
            default: return error.localizedDescription
            }
        }
        if let da = error as? DeviceActivityCenter.MonitoringError {
            switch da {
            case .excessiveActivities: return "Too many schedules are active. Turn some off and try again."
            case .intervalTooShort: return "Schedules need to be at least 15 minutes long."
            default: return error.localizedDescription
            }
        }
        return error.localizedDescription
    }
}
