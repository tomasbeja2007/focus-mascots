import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import UserNotifications

/// Runs in the background (even when Focus Crew is closed) to switch shields on
/// and off for schedules, and to lift focus shields when a session ends.
final class FocusMonitor: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        if activity == .focusSession {
            Shields.refreshFocus()
            return
        }
        guard let id = activity.scheduleID, let schedule = schedule(id) else { return }
        let weekday = Calendar.current.component(.weekday, from: Date())
        guard schedule.isEnabled, schedule.startsOn(weekday: weekday),
              let selection = SelectionStore.decode(schedule.selectionData), !selection.isEmptySelection else {
            return
        }
        Shields.apply(selection, to: .schedule(id), denyAppRemoval: schedule.strict)
        notify(
            id: "schedule-start-\(id.uuidString)",
            title: "\(schedule.name) has started",
            body: "\(schedule.mascot.name) is guarding \(selection.itemCount) item\(selection.itemCount == 1 ? "" : "s") until \(BlockSchedule.format(schedule.endMinutes))."
        )
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        if activity == .focusSession {
            liftFocusIfFinished(grace: 120)
            return
        }
        if let id = activity.scheduleID {
            Shields.clear(.schedule(id))
        }
    }

    /// For sessions shorter than 15 minutes the app schedules a longer interval and
    /// uses this warning, which fires exactly when the session ends.
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        if activity == .focusSession {
            liftFocusIfFinished(grace: 90)
        }
    }

    private func liftFocusIfFinished(grace: TimeInterval) {
        let now = Date()
        if let session = SharedFiles.activeSession.load(), !session.isPaused,
           session.endsAt.timeIntervalSince(now) > grace {
            // The session was extended or resumed later; the app re-scheduled monitoring.
            return
        }
        Shields.clear(.focus)
    }

    private func schedule(_ id: UUID) -> BlockSchedule? {
        (SharedFiles.schedules.load() ?? []).first { $0.id == id }
    }

    private func notify(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
