import AppIntents

/// Siri, Spotlight and Shortcuts phrases.
struct FocusCrewShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFocusIntent(),
            phrases: [
                "Start focusing with \(.applicationName)",
                "Start a \(.applicationName) session",
                "Focus with \(.applicationName)",
            ],
            shortTitle: "Start Focus",
            systemImageName: "scope"
        )
        AppShortcut(
            intent: PauseFocusIntent(),
            phrases: ["Pause \(.applicationName)", "Take a break in \(.applicationName)"],
            shortTitle: "Pause Focus",
            systemImageName: "pause.fill"
        )
        AppShortcut(
            intent: EndFocusIntent(),
            phrases: ["End my \(.applicationName) session", "Stop \(.applicationName)"],
            shortTitle: "End Focus",
            systemImageName: "stop.fill"
        )
    }

    static var shortcutTileColor: ShortcutTileColor = .navy
}
