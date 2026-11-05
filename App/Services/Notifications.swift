import Foundation
import UserNotifications

/// Local notifications: session end, daily reminder and streak saver.
enum Notifications {
    enum ID {
        static let sessionEnd = "session-end"
        static let dailyReminder = "daily-reminder"
        static let streakSaver = "streak-saver"
    }

    static var center: UNUserNotificationCenter { .current() }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    private static var chime: UNNotificationSound {
        UNNotificationSound(named: UNNotificationSoundName("chime.wav"))
    }

    static func scheduleSessionEnd(_ s: ActiveSession, enabled: Bool) {
        cancelSessionEnd()
        guard enabled, !s.isPaused else { return }
        let interval = s.endsAt.timeIntervalSinceNow
        guard interval > 1 else { return }
        let content = UNMutableNotificationContent()
        if s.kind == .rest {
            content.title = "Break's over"
            content.body = "\(s.mascot.name) is ready when you are. Start another session?"
        } else {
            content.title = "\(s.mascot.name): Session complete!"
            content.body = "\(s.mascot.line(from: s.mascot.completions, seed: s.plannedSeconds)) You focused for \(Format.longDuration(minutes: s.plannedSeconds / 60))."
        }
        content.sound = chime
        content.interruptionLevel = .timeSensitive
        content.userInfo = ["link": "focuscrew://session"]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        center.add(UNNotificationRequest(identifier: ID.sessionEnd, content: content, trigger: trigger))
    }

    static func cancelSessionEnd() {
        center.removePendingNotificationRequests(withIdentifiers: [ID.sessionEnd])
    }

    static func scheduleDailyReminder(enabled: Bool, minutes: Int, mascot: Mascot) {
        center.removePendingNotificationRequests(withIdentifiers: [ID.dailyReminder])
        guard enabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Time to focus with \(mascot.name)"
        content.body = mascot.line(from: mascot.greetings, seed: minutes)
        content.sound = UNNotificationSound(named: UNNotificationSoundName("nudge.wav"))
        content.userInfo = ["link": "focuscrew://home"]
        var comps = DateComponents()
        comps.hour = minutes / 60
        comps.minute = minutes % 60
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: ID.dailyReminder, content: content, trigger: trigger))
    }

    /// An evening nudge when today has no session yet and a streak is at risk.
    static func scheduleStreakSaver(enabled: Bool, focusedToday: Bool, streak: Int, mascot: Mascot) {
        center.removePendingNotificationRequests(withIdentifiers: [ID.streakSaver])
        guard enabled, !focusedToday, streak > 0 else { return }
        let cal = Calendar.current
        guard let fireDate = cal.date(bySettingHour: 20, minute: 0, second: 0, of: Date()), fireDate > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Don't break your \(streak)-day streak!"
        content.body = "A quick 10-minute session with \(mascot.name) keeps it alive."
        content.sound = UNNotificationSound(named: UNNotificationSoundName("nudge.wav"))
        content.userInfo = ["link": "focuscrew://start?minutes=10"]
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: ID.streakSaver, content: content, trigger: trigger))
    }

    static func removeAll() {
        center.removeAllPendingNotificationRequests()
    }
}

/// Keeps session banners quiet while the app is open (the app shows its own
/// celebration) and routes notification taps to deep links.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    var onOpenLink: ((URL) -> Void)?

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        if notification.request.identifier == Notifications.ID.sessionEnd { return [] }
        return [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        if let link = response.notification.request.content.userInfo["link"] as? String, let url = URL(string: link) {
            await MainActor.run { onOpenLink?(url) }
        }
    }
}
