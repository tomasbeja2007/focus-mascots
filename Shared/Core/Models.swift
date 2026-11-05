import Foundation

// MARK: - Settings

enum AmbientSound: String, Codable, CaseIterable, Identifiable {
    case off, brown, pink, white, rain, ocean

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off: return "Off"
        case .brown: return "Brown noise"
        case .pink: return "Pink noise"
        case .white: return "White noise"
        case .rain: return "Soft rain"
        case .ocean: return "Ocean waves"
        }
    }

    var symbol: String {
        switch self {
        case .off: return "speaker.slash.fill"
        case .brown: return "waveform"
        case .pink: return "waveform.path"
        case .white: return "wind"
        case .rain: return "cloud.rain.fill"
        case .ocean: return "water.waves"
        }
    }
}

enum AppearancePreference: String, Codable, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "Automatic"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

struct AppSettings: Codable, Equatable {
    var dailyGoalMinutes: Int = 90
    var defaultSessionMinutes: Int = 25
    var breakMinutes: Int = 5
    var strictByDefault: Bool = false
    var allowPauses: Bool = true
    var blockDuringFocus: Bool = true
    var ambientSound: AmbientSound = .off
    var ambientVolume: Double = 0.6
    var chimeEnabled: Bool = true
    var hapticsEnabled: Bool = true
    var liveActivitiesEnabled: Bool = true
    var sessionEndAlerts: Bool = true
    var dailyReminderEnabled: Bool = false
    var dailyReminderMinutes: Int = 9 * 60
    var streakReminderEnabled: Bool = true
    var syncToMac: Bool = true
    var appearance: AppearancePreference = .system

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppSettings()
        dailyGoalMinutes = (try? c.decodeIfPresent(Int.self, forKey: .dailyGoalMinutes)) ?? d.dailyGoalMinutes
        defaultSessionMinutes = (try? c.decodeIfPresent(Int.self, forKey: .defaultSessionMinutes)) ?? d.defaultSessionMinutes
        breakMinutes = (try? c.decodeIfPresent(Int.self, forKey: .breakMinutes)) ?? d.breakMinutes
        strictByDefault = (try? c.decodeIfPresent(Bool.self, forKey: .strictByDefault)) ?? d.strictByDefault
        allowPauses = (try? c.decodeIfPresent(Bool.self, forKey: .allowPauses)) ?? d.allowPauses
        blockDuringFocus = (try? c.decodeIfPresent(Bool.self, forKey: .blockDuringFocus)) ?? d.blockDuringFocus
        ambientSound = (try? c.decodeIfPresent(AmbientSound.self, forKey: .ambientSound)) ?? d.ambientSound
        ambientVolume = (try? c.decodeIfPresent(Double.self, forKey: .ambientVolume)) ?? d.ambientVolume
        chimeEnabled = (try? c.decodeIfPresent(Bool.self, forKey: .chimeEnabled)) ?? d.chimeEnabled
        hapticsEnabled = (try? c.decodeIfPresent(Bool.self, forKey: .hapticsEnabled)) ?? d.hapticsEnabled
        liveActivitiesEnabled = (try? c.decodeIfPresent(Bool.self, forKey: .liveActivitiesEnabled)) ?? d.liveActivitiesEnabled
        sessionEndAlerts = (try? c.decodeIfPresent(Bool.self, forKey: .sessionEndAlerts)) ?? d.sessionEndAlerts
        dailyReminderEnabled = (try? c.decodeIfPresent(Bool.self, forKey: .dailyReminderEnabled)) ?? d.dailyReminderEnabled
        dailyReminderMinutes = (try? c.decodeIfPresent(Int.self, forKey: .dailyReminderMinutes)) ?? d.dailyReminderMinutes
        streakReminderEnabled = (try? c.decodeIfPresent(Bool.self, forKey: .streakReminderEnabled)) ?? d.streakReminderEnabled
        syncToMac = (try? c.decodeIfPresent(Bool.self, forKey: .syncToMac)) ?? d.syncToMac
        appearance = (try? c.decodeIfPresent(AppearancePreference.self, forKey: .appearance)) ?? d.appearance
    }
}

// MARK: - Sessions

enum SessionKind: String, Codable {
    case focus, rest
}

/// A finished (or abandoned) session.
struct FocusSessionRecord: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var startedAt: Date
    var endedAt: Date
    var plannedSeconds: Int
    var focusedSeconds: Int
    var completed: Bool
    var mascot: Mascot
    var intention: String = ""
    var strict: Bool = false
    var kind: SessionKind = .focus

    var focusedMinutes: Int { Int((Double(focusedSeconds) / 60).rounded()) }
}

/// The session currently running. Shared with widgets, extensions and the Mac.
struct ActiveSession: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var kind: SessionKind = .focus
    var startedAt: Date
    var plannedSeconds: Int
    /// When the session ends if it is not paused again.
    var endsAt: Date
    var pausedAt: Date?
    var pausedSeconds: Double = 0
    var mascot: Mascot
    var intention: String = ""
    var strict: Bool = false
    var blocking: Bool = false
    var blockedItems: Int = 0
    var deviceName: String = "iPhone"

    init(kind: SessionKind = .focus, minutes: Int, mascot: Mascot, intention: String = "", strict: Bool = false, blocking: Bool = false, blockedItems: Int = 0, start: Date = Date()) {
        self.kind = kind
        self.startedAt = start
        self.plannedSeconds = max(60, minutes * 60)
        self.endsAt = start.addingTimeInterval(TimeInterval(max(60, minutes * 60)))
        self.mascot = mascot
        self.intention = intention
        self.strict = strict
        self.blocking = blocking
        self.blockedItems = blockedItems
    }

    var isPaused: Bool { pausedAt != nil }

    func remaining(at date: Date = Date()) -> TimeInterval {
        if let pausedAt { return max(0, endsAt.timeIntervalSince(pausedAt)) }
        return max(0, endsAt.timeIntervalSince(date))
    }

    func elapsed(at date: Date = Date()) -> TimeInterval {
        max(0, TimeInterval(plannedSeconds) - remaining(at: date))
    }

    func progress(at date: Date = Date()) -> Double {
        guard plannedSeconds > 0 else { return 1 }
        return min(1, max(0, elapsed(at: date) / TimeInterval(plannedSeconds)))
    }

    func isFinished(at date: Date = Date()) -> Bool {
        !isPaused && date >= endsAt
    }

    /// The window to show in countdown text views.
    var countdownRange: ClosedRange<Date> {
        let start = min(startedAt, endsAt)
        return start...endsAt
    }
}

// MARK: - Schedules

/// A recurring block, e.g. "Work hours, weekdays 9:00 – 17:00".
struct BlockSchedule: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var symbol: String
    var startMinutes: Int
    var endMinutes: Int
    /// Calendar weekdays (1 = Sunday ... 7 = Saturday).
    var weekdays: [Int]
    var isEnabled: Bool = true
    var mascot: Mascot = .pebble
    var strict: Bool = false
    /// Encoded `FamilyActivitySelection` (iOS only).
    var selectionData: Data?
    var appCount: Int = 0
    var categoryCount: Int = 0
    var webCount: Int = 0

    var crossesMidnight: Bool { endMinutes <= startMinutes }

    var blockedItemCount: Int { appCount + categoryCount + webCount }

    func isActive(at date: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard isEnabled else { return false }
        let comps = calendar.dateComponents([.hour, .minute, .weekday], from: date)
        let minute = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        let weekday = comps.weekday ?? 1
        let yesterday = weekday == 1 ? 7 : weekday - 1
        if crossesMidnight {
            return (weekdays.contains(weekday) && minute >= startMinutes)
                || (weekdays.contains(yesterday) && minute < endMinutes)
        }
        return weekdays.contains(weekday) && minute >= startMinutes && minute < endMinutes
    }

    /// Whether the block is supposed to start on the given weekday.
    func startsOn(weekday: Int) -> Bool { weekdays.contains(weekday) }

    var timeRangeText: String {
        "\(BlockSchedule.format(startMinutes)) – \(BlockSchedule.format(endMinutes))"
    }

    var daysText: String {
        let set = Set(weekdays)
        if set.count == 7 { return "Every day" }
        if set == [2, 3, 4, 5, 6] { return "Weekdays" }
        if set == [1, 7] { return "Weekends" }
        let symbols = Calendar.current.shortWeekdaySymbols
        return weekdays.sorted { BlockSchedule.mondayFirst($0) < BlockSchedule.mondayFirst($1) }
            .map { symbols[$0 - 1] }
            .joined(separator: ", ")
    }

    static func mondayFirst(_ weekday: Int) -> Int { weekday == 1 ? 8 : weekday }

    static func format(_ minutes: Int) -> String {
        var comps = DateComponents()
        comps.hour = (minutes / 60) % 24
        comps.minute = minutes % 60
        let date = Calendar.current.date(from: comps) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    static let templates: [BlockSchedule] = [
        BlockSchedule(name: "Work hours", symbol: "briefcase.fill", startMinutes: 9 * 60, endMinutes: 17 * 60, weekdays: [2, 3, 4, 5, 6], mascot: .orbit),
        BlockSchedule(name: "Study time", symbol: "book.fill", startMinutes: 16 * 60, endMinutes: 19 * 60, weekdays: [2, 3, 4, 5, 6], mascot: .blob),
        BlockSchedule(name: "Bedtime", symbol: "moon.stars.fill", startMinutes: 22 * 60 + 30, endMinutes: 7 * 60, weekdays: [1, 2, 3, 4, 5, 6, 7], mascot: .leaf),
        BlockSchedule(name: "Morning routine", symbol: "sunrise.fill", startMinutes: 6 * 60 + 30, endMinutes: 9 * 60, weekdays: [1, 2, 3, 4, 5, 6, 7], mascot: .spark),
        BlockSchedule(name: "No-phone dinner", symbol: "fork.knife", startMinutes: 19 * 60, endMinutes: 20 * 60 + 30, weekdays: [1, 2, 3, 4, 5, 6, 7], mascot: .pebble),
    ]
}

// MARK: - Snapshot for widgets, shield and Mac

/// A small, denormalised view of the app state written whenever something
/// changes, so widgets and extensions never have to recompute statistics.
struct CrewSnapshot: Codable, Equatable {
    var name: String
    var mascot: Mascot
    var active: ActiveSession?
    var todayFocusSeconds: Int
    var dailyGoalMinutes: Int
    var streak: Int
    /// Focus minutes for the last 7 days, oldest first, today last.
    var weekMinutes: [Int]
    var totalSessions: Int
    var totalFocusSeconds: Int
    var defaultMinutes: Int
    var updatedAt: Date

    var goalProgress: Double {
        guard dailyGoalMinutes > 0 else { return 0 }
        return min(1, Double(todayFocusSeconds) / Double(dailyGoalMinutes * 60))
    }

    static let placeholder = CrewSnapshot(
        name: "Alex", mascot: .orbit, active: nil, todayFocusSeconds: 52 * 60, dailyGoalMinutes: 90,
        streak: 6, weekMinutes: [45, 80, 30, 95, 60, 25, 52], totalSessions: 42, totalFocusSeconds: 31 * 3600,
        defaultMinutes: 25, updatedAt: Date()
    )
}

// MARK: - Formatting helpers

enum Format {
    /// 1:05:09 / 25:00
    static func clock(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds.rounded(.up)))
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }

    /// "1h 25m", "45m", "0m"
    static func duration(seconds: Int) -> String {
        let minutes = Int((Double(seconds) / 60).rounded())
        return duration(minutes: minutes)
    }

    static func duration(minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    /// "1 hr 25 min"
    static func longDuration(minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h > 0 && m > 0 { return "\(h) hr \(m) min" }
        if h > 0 { return "\(h) hr" }
        return "\(m) min"
    }
}
