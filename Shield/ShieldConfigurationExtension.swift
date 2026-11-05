import ManagedSettings
import ManagedSettingsUI
import UIKit

/// The screen people see when they open a blocked app: a crew member with a message.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        make(name: application.localizedDisplayName)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        make(name: application.localizedDisplayName ?? category.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        make(name: webDomain.domain)
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        make(name: webDomain.domain ?? category.localizedDisplayName)
    }

    private func make(name: String?) -> ShieldConfiguration {
        let context = ShieldContext.current()
        let mascot: Mascot
        let title: String
        let subtitle: String
        var strict = false
        let appName = name ?? "This app"

        switch context {
        case .focus(let session):
            mascot = session.mascot
            strict = session.strict
            title = mascot.shieldTitle
            let ends = session.endsAt.formatted(date: .omitted, time: .shortened)
            let goal = session.intention.isEmpty ? "your focus session" : "\u{201C}\(session.intention)\u{201D}"
            subtitle = "\(appName) is blocked while you work on \(goal). It unlocks at \(ends). You've got this!"
        case .schedule(let schedule):
            mascot = schedule.mascot
            strict = schedule.strict
            title = "\(schedule.name) is on"
            subtitle = "\(appName) is blocked until \(BlockSchedule.format(schedule.endMinutes)). \(mascot.name) believes in you."
        case .none:
            mascot = SharedFiles.snapshot.load()?.mascot ?? .orbit
            title = mascot.shieldTitle
            subtitle = "\(appName) is blocked by Focus Crew right now."
        }

        let tint = UIColor(named: "\(mascot.name)Tint") ?? UIColor.systemBackground
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: tint.withAlphaComponent(0.55),
            icon: UIImage(named: mascot.asset(strict ? .focused : .idle)),
            title: ShieldConfiguration.Label(text: title, color: UIColor.label),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: UIColor.secondaryLabel),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Back to focus", color: UIColor.white),
            primaryButtonBackgroundColor: UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1),
            secondaryButtonLabel: strict ? nil : ShieldConfiguration.Label(text: "I need a break", color: UIColor.secondaryLabel)
        )
    }
}
