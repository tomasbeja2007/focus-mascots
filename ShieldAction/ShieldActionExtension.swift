import ManagedSettings
import UserNotifications

/// Handles the buttons on the shield.
///   * "Back to focus" closes the blocked app.
///   * "I need a break" sends a notification that opens Focus Crew, where the
///     session can be paused properly (and honestly).
final class ShieldActionExtension: ShieldActionDelegate {
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(respond(to: action))
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(respond(to: action))
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(respond(to: action))
    }

    private func respond(to action: ShieldAction) -> ShieldActionResponse {
        switch action {
        case .primaryButtonPressed:
            return .close
        case .secondaryButtonPressed:
            sendBreakNotification()
            return .close
        default:
            return .close
        }
    }

    private func sendBreakNotification() {
        let mascot = SharedFiles.snapshot.load()?.mascot ?? .orbit
        let content = UNMutableNotificationContent()
        content.title = "Need a breather?"
        content.body = "Tap to pause your session in Focus Crew. \(mascot.name) will hold your spot."
        content.sound = .default
        content.userInfo = ["link": "focuscrew://session"]
        let request = UNNotificationRequest(identifier: "shield-break", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
