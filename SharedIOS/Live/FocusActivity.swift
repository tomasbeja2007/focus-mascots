import ActivityKit
import AppIntents
import Foundation

/// Live Activity (Lock Screen + Dynamic Island) for a running session.
struct FocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startedAt: Date
        var endsAt: Date
        /// Seconds left when paused; nil while running.
        var pausedRemaining: Double?
        var isRest: Bool
        var mood: String
        var finished: Bool = false

        var isPaused: Bool { pausedRemaining != nil }

        var mascotMood: MascotMood { MascotMood(rawValue: mood) ?? .focused }
    }

    var mascot: Mascot
    var intention: String
    var plannedSeconds: Int
    var strict: Bool
}

/// Lets intents that run in the app process reach the app's session engine.
/// The widget extension never sets these, it only needs the types to compile.
enum IntentBridge {
    static var startFocus: ((Int?) async -> Void)?
    static var pause: (() async -> Void)?
    static var resume: (() async -> Void)?
    static var end: (() async -> Void)?
}

/// Start a focus session (Shortcuts, Siri, Spotlight, Control Center).
struct StartFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Focus Session"
    static var description = IntentDescription("Starts a focus session with your Focus Crew companion and blocks your distracting apps.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Minutes")
    var minutes: Int?

    init() {}

    init(minutes: Int?) {
        self.minutes = minutes
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        await IntentBridge.startFocus?(minutes)
        return .result()
    }
}

/// Pause / take a break from the Live Activity.
struct PauseFocusIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Focus Session"
    static var description = IntentDescription("Pauses the current session and lifts the app shields.")

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        await IntentBridge.pause?()
        return .result()
    }
}

struct ResumeFocusIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume Focus Session"
    static var description = IntentDescription("Resumes the paused session.")

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        await IntentBridge.resume?()
        return .result()
    }
}

struct EndFocusIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "End Focus Session"
    static var description = IntentDescription("Ends the current session.")

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        await IntentBridge.end?()
        return .result()
    }
}
