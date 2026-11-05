import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

// Shared between the app and the Screen Time extensions (monitor, shield, shield action).

extension ManagedSettingsStore.Name {
    /// Shields applied while a focus session is running.
    static let focus = Self("focus")

    /// Shields owned by a recurring schedule.
    static func schedule(_ id: UUID) -> Self { Self("schedule.\(id.uuidString)") }
}

extension DeviceActivityName {
    /// Monitors the end of the current focus session, so shields come down even
    /// if the app is not running.
    static let focusSession = Self("focus.session")

    static func schedule(_ id: UUID) -> Self { Self("schedule.\(id.uuidString)") }

    var scheduleID: UUID? {
        let prefix = "schedule."
        guard rawValue.hasPrefix(prefix) else { return nil }
        return UUID(uuidString: String(rawValue.dropFirst(prefix.count)))
    }
}

extension FamilyActivitySelection {
    var itemCount: Int { applicationTokens.count + categoryTokens.count + webDomainTokens.count }
    var isEmptySelection: Bool { itemCount == 0 }

    var summary: String {
        var parts: [String] = []
        if !applicationTokens.isEmpty { parts.append("\(applicationTokens.count) app\(applicationTokens.count == 1 ? "" : "s")") }
        if !categoryTokens.isEmpty { parts.append("\(categoryTokens.count) categor\(categoryTokens.count == 1 ? "y" : "ies")") }
        if !webDomainTokens.isEmpty { parts.append("\(webDomainTokens.count) site\(webDomainTokens.count == 1 ? "" : "s")") }
        return parts.isEmpty ? "Nothing selected" : parts.joined(separator: " · ")
    }
}

/// Persists Screen Time selections in the App Group.
enum SelectionStore {
    private static let focusFile = SharedFile<FamilyActivitySelection>(name: "focus-selection.json")

    static func loadFocus() -> FamilyActivitySelection {
        focusFile.load() ?? FamilyActivitySelection()
    }

    static func saveFocus(_ selection: FamilyActivitySelection) {
        focusFile.save(selection)
    }

    static func decode(_ data: Data?) -> FamilyActivitySelection? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    static func encode(_ selection: FamilyActivitySelection) -> Data? {
        try? JSONEncoder().encode(selection)
    }
}

/// Turns selections into shields.
enum Shields {
    static func apply(_ selection: FamilyActivitySelection, to name: ManagedSettingsStore.Name, denyAppRemoval: Bool = false) {
        let store = ManagedSettingsStore(named: name)
        let apps = selection.applicationTokens
        let categories = selection.categoryTokens
        let domains = selection.webDomainTokens
        store.shield.applications = apps.isEmpty ? nil : apps
        store.shield.applicationCategories = categories.isEmpty ? nil : .specific(categories)
        store.shield.webDomains = domains.isEmpty ? nil : domains
        store.shield.webDomainCategories = categories.isEmpty ? nil : .specific(categories)
        store.application.denyAppRemoval = denyAppRemoval ? true : nil
    }

    static func clear(_ name: ManagedSettingsStore.Name) {
        ManagedSettingsStore(named: name).clearAllSettings()
    }

    /// Re-applies or clears a schedule's shields depending on whether it is active right now.
    static func refresh(schedule: BlockSchedule, at date: Date = Date()) {
        if schedule.isActive(at: date), let selection = SelectionStore.decode(schedule.selectionData), !selection.isEmptySelection {
            apply(selection, to: .schedule(schedule.id), denyAppRemoval: schedule.strict)
        } else {
            clear(.schedule(schedule.id))
        }
    }

    /// Applies focus shields if a focus session is running and not paused, otherwise clears them.
    static func refreshFocus(at date: Date = Date()) {
        if let session = SharedFiles.activeSession.load(), session.kind == .focus, session.blocking,
           !session.isPaused, !session.isFinished(at: date) {
            apply(SelectionStore.loadFocus(), to: .focus, denyAppRemoval: session.strict)
        } else {
            clear(.focus)
        }
    }
}

/// What is currently blocking apps, for the shield screen's copy.
enum ShieldContext {
    case focus(ActiveSession)
    case schedule(BlockSchedule)
    case none

    static func current(at date: Date = Date()) -> ShieldContext {
        if let s = SharedFiles.activeSession.load(), s.kind == .focus, s.blocking, !s.isPaused, !s.isFinished(at: date) {
            return .focus(s)
        }
        if let schedule = (SharedFiles.schedules.load() ?? []).first(where: { $0.isActive(at: date) }) {
            return .schedule(schedule)
        }
        return .none
    }
}
