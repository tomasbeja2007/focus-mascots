import Foundation

/// Derived numbers for insights, widgets and achievements.
struct FocusStats {
    let history: [FocusSessionRecord]
    var calendar: Calendar = .current

    var focusSessions: [FocusSessionRecord] { history.filter { $0.kind == .focus } }

    func focusSeconds(on day: Date) -> Int {
        focusSessions
            .filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
            .reduce(0) { $0 + $1.focusedSeconds }
    }

    func sessions(on day: Date) -> [FocusSessionRecord] {
        focusSessions.filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
    }

    /// Focus minutes per day for the last `days` days, oldest first.
    func dailyMinutes(lastDays days: Int, endingAt end: Date = Date()) -> [DayTotal] {
        let today = calendar.startOfDay(for: end)
        return (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DayTotal(date: day, minutes: focusSeconds(on: day) / 60)
        }
    }

    /// A day counts towards the streak when at least one focus session was completed.
    private func isStreakDay(_ day: Date) -> Bool {
        focusSessions.contains { $0.completed && calendar.isDate($0.startedAt, inSameDayAs: day) }
    }

    func currentStreak(today: Date = Date()) -> Int {
        var day = calendar.startOfDay(for: today)
        // Today not done yet? The streak is still alive if yesterday counted.
        if !isStreakDay(day) {
            guard let y = calendar.date(byAdding: .day, value: -1, to: day), isStreakDay(y) else { return 0 }
            day = y
        }
        var count = 0
        while isStreakDay(day) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    func bestStreak() -> Int {
        let days = Set(focusSessions.filter(\.completed).map { calendar.startOfDay(for: $0.startedAt) }).sorted()
        var best = 0, run = 0
        var previous: Date?
        for d in days {
            if let p = previous, let next = calendar.date(byAdding: .day, value: 1, to: p), calendar.isDate(next, inSameDayAs: d) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = d
        }
        return best
    }

    var totalFocusSeconds: Int { focusSessions.reduce(0) { $0 + $1.focusedSeconds } }
    var completedCount: Int { focusSessions.filter(\.completed).count }

    var completionRate: Double {
        guard !focusSessions.isEmpty else { return 0 }
        return Double(completedCount) / Double(focusSessions.count)
    }

    var averageSessionMinutes: Int {
        let done = focusSessions.filter(\.completed)
        guard !done.isEmpty else { return 0 }
        return done.reduce(0) { $0 + $1.focusedSeconds } / done.count / 60
    }

    /// Focus seconds started in each hour of the day (0...23).
    var hourHistogram: [Int] {
        var buckets = Array(repeating: 0, count: 24)
        for s in focusSessions {
            let h = calendar.component(.hour, from: s.startedAt)
            buckets[h] += s.focusedSeconds
        }
        return buckets
    }

    var bestHour: Int? {
        let h = hourHistogram
        guard let maxValue = h.max(), maxValue > 0 else { return nil }
        return h.firstIndex(of: maxValue)
    }

    func focusSeconds(with mascot: Mascot) -> Int {
        focusSessions.filter { $0.mascot == mascot }.reduce(0) { $0 + $1.focusedSeconds }
    }

    func bond(with mascot: Mascot) -> BondLevel {
        BondLevel(minutes: focusSeconds(with: mascot) / 60)
    }

    func seconds(in interval: DateInterval) -> Int {
        focusSessions.filter { interval.contains($0.startedAt) }.reduce(0) { $0 + $1.focusedSeconds }
    }
}

struct DayTotal: Identifiable, Equatable {
    let date: Date
    let minutes: Int
    var id: Date { date }
}

/// Friendship level with a mascot, earned by focusing together.
struct BondLevel: Equatable {
    let minutes: Int

    /// Minutes needed to reach `level` (level 1 starts at 0).
    static func threshold(for level: Int) -> Int {
        guard level > 1 else { return 0 }
        // 60, 180, 360, 600, 900 ... (triangular growth)
        let n = level - 1
        return 30 * n * (n + 1)
    }

    var level: Int {
        var l = 1
        while minutes >= BondLevel.threshold(for: l + 1) { l += 1 }
        return l
    }

    var progress: Double {
        let lo = BondLevel.threshold(for: level), hi = BondLevel.threshold(for: level + 1)
        guard hi > lo else { return 1 }
        return Double(minutes - lo) / Double(hi - lo)
    }

    var minutesToNext: Int { BondLevel.threshold(for: level + 1) - minutes }

    var title: String {
        switch level {
        case 1: return "New friends"
        case 2: return "Getting along"
        case 3: return "Focus buddies"
        case 4: return "Trusted partners"
        case 5: return "Best friends"
        case 6...8: return "Inseparable"
        default: return "Legendary duo"
        }
    }
}

// MARK: - Achievements

enum Achievement: String, CaseIterable, Identifiable, Codable {
    case firstSession, streak3, streak7, streak30, hour1, hours10, hours50, marathon
    case earlyBird, nightOwl, ironWill, fiveADay, crewTour, goalGetter, weekend, planner

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstSession: return "Lift-off"
        case .streak3: return "On a roll"
        case .streak7: return "Week warrior"
        case .streak30: return "Unstoppable"
        case .hour1: return "First hour"
        case .hours10: return "Deep diver"
        case .hours50: return "Focus master"
        case .marathon: return "Marathon"
        case .earlyBird: return "Early bird"
        case .nightOwl: return "Night owl"
        case .ironWill: return "Iron will"
        case .fiveADay: return "Five a day"
        case .crewTour: return "Crew tour"
        case .goalGetter: return "Goal getter"
        case .weekend: return "Weekend focus"
        case .planner: return "Planner"
        }
    }

    var detail: String {
        switch self {
        case .firstSession: return "Complete your first focus session."
        case .streak3: return "Focus 3 days in a row."
        case .streak7: return "Focus 7 days in a row."
        case .streak30: return "Focus 30 days in a row."
        case .hour1: return "Focus for 1 hour in total."
        case .hours10: return "Focus for 10 hours in total."
        case .hours50: return "Focus for 50 hours in total."
        case .marathon: return "Finish a single 90-minute session."
        case .earlyBird: return "Finish a session before 8 AM."
        case .nightOwl: return "Finish a session after 10 PM."
        case .ironWill: return "Finish a session in strict mode."
        case .fiveADay: return "Finish 5 sessions in one day."
        case .crewTour: return "Focus with all five crew members."
        case .goalGetter: return "Hit your daily focus goal."
        case .weekend: return "Finish a session on a weekend."
        case .planner: return "Create a blocking schedule."
        }
    }

    var symbol: String {
        switch self {
        case .firstSession: return "paperplane.fill"
        case .streak3: return "flame.fill"
        case .streak7: return "flame.circle.fill"
        case .streak30: return "crown.fill"
        case .hour1: return "clock.fill"
        case .hours10: return "water.waves"
        case .hours50: return "mountain.2.fill"
        case .marathon: return "figure.run"
        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        case .ironWill: return "lock.fill"
        case .fiveADay: return "hand.raised.fingers.spread.fill"
        case .crewTour: return "person.3.fill"
        case .goalGetter: return "target"
        case .weekend: return "sun.max.fill"
        case .planner: return "calendar.badge.clock"
        }
    }

    /// The crew member who hands out the badge.
    var mascot: Mascot {
        switch self {
        case .firstSession, .hour1, .crewTour: return .orbit
        case .streak3, .fiveADay, .earlyBird, .weekend: return .spark
        case .nightOwl, .hours10: return .leaf
        case .ironWill, .marathon, .streak30, .planner: return .pebble
        case .streak7, .hours50, .goalGetter: return .blob
        }
    }

    /// (current, target) for the progress bar.
    func progress(stats: FocusStats, dailyGoalMinutes: Int, scheduleCount: Int) -> (Double, Double) {
        let done = stats.focusSessions.filter(\.completed)
        let cal = stats.calendar
        func b(_ v: Bool) -> (Double, Double) { (v ? 1 : 0, 1) }
        switch self {
        case .firstSession: return (Double(min(1, done.count)), 1)
        case .streak3: return (Double(min(3, stats.bestStreak())), 3)
        case .streak7: return (Double(min(7, stats.bestStreak())), 7)
        case .streak30: return (Double(min(30, stats.bestStreak())), 30)
        case .hour1: return (min(60, Double(stats.totalFocusSeconds) / 60), 60)
        case .hours10: return (min(600, Double(stats.totalFocusSeconds) / 60), 600)
        case .hours50: return (min(3000, Double(stats.totalFocusSeconds) / 60), 3000)
        case .marathon: return b(done.contains { $0.focusedSeconds >= 90 * 60 })
        case .earlyBird: return b(done.contains { cal.component(.hour, from: $0.endedAt) < 8 })
        case .nightOwl: return b(done.contains { cal.component(.hour, from: $0.endedAt) >= 22 })
        case .ironWill: return b(done.contains { $0.strict })
        case .fiveADay:
            let perDay = Dictionary(grouping: done) { cal.startOfDay(for: $0.startedAt) }.values.map(\.count).max() ?? 0
            return (Double(min(5, perDay)), 5)
        case .crewTour:
            return (Double(Set(stats.focusSessions.map(\.mascot)).count), 5)
        case .goalGetter:
            let perDay = Dictionary(grouping: stats.focusSessions) { cal.startOfDay(for: $0.startedAt) }
                .values.map { $0.reduce(0) { $0 + $1.focusedSeconds } }.max() ?? 0
            return (min(Double(dailyGoalMinutes), Double(perDay) / 60), Double(max(1, dailyGoalMinutes)))
        case .weekend: return b(done.contains { cal.isDateInWeekend($0.startedAt) })
        case .planner: return b(scheduleCount > 0)
        }
    }

    func isUnlocked(stats: FocusStats, dailyGoalMinutes: Int, scheduleCount: Int) -> Bool {
        let (cur, target) = progress(stats: stats, dailyGoalMinutes: dailyGoalMinutes, scheduleCount: scheduleCount)
        return cur >= target
    }
}
