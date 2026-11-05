import XCTest

/// Tests for the platform-independent core (Shared/Core), compiled straight into this bundle.
final class MatcherTests: XCTestCase {
    func testProcrastinatorWhoWantsEnergyGetsSpark() {
        var p = UserProfile()
        p.struggles = [.procrastination, .motivation]
        p.focusSpan = .under5
        p.motivation = .energy
        XCTAssertEqual(MascotMatcher.match(p).mascot, .spark)
    }

    func testToughLoveScrollerGetsPebble() {
        var p = UserProfile()
        p.struggles = [.scrolling]
        p.dailyScreenHours = 8
        p.motivation = .toughLove
        XCTAssertEqual(MascotMatcher.match(p).mascot, .pebble)
    }

    func testSleepAndCalmGetsLeaf() {
        var p = UserProfile()
        p.struggles = [.sleep, .breaks]
        p.hardestTimes = [.bedtime]
        p.goal = .sleep
        p.motivation = .calm
        XCTAssertEqual(MascotMatcher.match(p).mascot, .leaf)
    }

    func testDataLoverGetsBlob() {
        var p = UserProfile()
        p.goal = .habits
        p.motivation = .data
        p.role = .founder
        XCTAssertEqual(MascotMatcher.match(p).mascot, .blob)
    }

    func testDeepWorkerGetsOrbit() {
        var p = UserProfile()
        p.struggles = [.focus]
        p.goal = .deepWork
        p.motivation = .gentle
        p.role = .professional
        XCTAssertEqual(MascotMatcher.match(p).mascot, .orbit)
    }

    func testEmptyProfileFallsBackToOrbit() {
        XCTAssertEqual(MascotMatcher.match(UserProfile()).mascot, .orbit)
    }

    func testReasonsAreNeverEmpty() {
        for m in Mascot.allCases {
            XCTAssertFalse(MascotMatcher.reasons(for: m, UserProfile()).isEmpty, "\(m)")
        }
    }

    func testYearsOnPhone() {
        var p = UserProfile()
        p.age = .age25to34   // mid age 30 -> 50 years left
        p.dailyScreenHours = 6
        XCTAssertEqual(MascotMatcher.yearsOnPhone(p), 12.5, accuracy: 0.001)
        XCTAssertEqual(MascotMatcher.yearsSaved(cuttingHours: 2, p), 50.0 / 12.0, accuracy: 0.001)
    }
}

final class StatsTests: XCTestCase {
    private let cal = Calendar.current

    private func session(daysAgo: Int, minutes: Int = 25, completed: Bool = true, hour: Int = 10, mascot: Mascot = .orbit) -> FocusSessionRecord {
        let day = cal.date(byAdding: .day, value: -daysAgo, to: cal.startOfDay(for: Date()))!
        let start = cal.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
        return FocusSessionRecord(
            startedAt: start, endedAt: start.addingTimeInterval(TimeInterval(minutes * 60)),
            plannedSeconds: minutes * 60, focusedSeconds: minutes * 60, completed: completed, mascot: mascot
        )
    }

    func testStreakIncludesToday() {
        let stats = FocusStats(history: [session(daysAgo: 0), session(daysAgo: 1), session(daysAgo: 2), session(daysAgo: 4)])
        XCTAssertEqual(stats.currentStreak(), 3)
    }

    func testStreakStillAliveWhenTodayNotDoneYet() {
        let stats = FocusStats(history: [session(daysAgo: 1), session(daysAgo: 2)])
        XCTAssertEqual(stats.currentStreak(), 2)
    }

    func testStreakBrokenAfterMissedDay() {
        let stats = FocusStats(history: [session(daysAgo: 2), session(daysAgo: 3)])
        XCTAssertEqual(stats.currentStreak(), 0)
    }

    func testAbandonedSessionsDontCountForStreak() {
        let stats = FocusStats(history: [session(daysAgo: 0, completed: false)])
        XCTAssertEqual(stats.currentStreak(), 0)
    }

    func testBestStreak() {
        let stats = FocusStats(history: [0, 1, 5, 6, 7, 8, 12].map { session(daysAgo: $0) })
        XCTAssertEqual(stats.bestStreak(), 4)
    }

    func testDailyMinutesOldestFirst() {
        let stats = FocusStats(history: [session(daysAgo: 0, minutes: 30), session(daysAgo: 6, minutes: 45)])
        let days = stats.dailyMinutes(lastDays: 7)
        XCTAssertEqual(days.count, 7)
        XCTAssertEqual(days.first?.minutes, 45)
        XCTAssertEqual(days.last?.minutes, 30)
    }

    func testBestHourAndBond() {
        let stats = FocusStats(history: [session(daysAgo: 0, minutes: 60, hour: 9), session(daysAgo: 1, minutes: 120, hour: 9, mascot: .spark), session(daysAgo: 2, minutes: 10, hour: 20)])
        XCTAssertEqual(stats.bestHour, 9)
        XCTAssertEqual(stats.bond(with: .spark).level, 2)
        XCTAssertEqual(stats.bond(with: .orbit).minutes, 70)
    }

    func testAchievements() {
        let stats = FocusStats(history: [session(daysAgo: 0, minutes: 95)])
        XCTAssertTrue(Achievement.firstSession.isUnlocked(stats: stats, dailyGoalMinutes: 90, scheduleCount: 0))
        XCTAssertTrue(Achievement.marathon.isUnlocked(stats: stats, dailyGoalMinutes: 90, scheduleCount: 0))
        XCTAssertTrue(Achievement.goalGetter.isUnlocked(stats: stats, dailyGoalMinutes: 90, scheduleCount: 0))
        XCTAssertFalse(Achievement.streak3.isUnlocked(stats: stats, dailyGoalMinutes: 90, scheduleCount: 0))
        XCTAssertTrue(Achievement.planner.isUnlocked(stats: stats, dailyGoalMinutes: 90, scheduleCount: 1))
    }
}

final class BondLevelTests: XCTestCase {
    func testThresholds() {
        XCTAssertEqual(BondLevel(minutes: 0).level, 1)
        XCTAssertEqual(BondLevel(minutes: 59).level, 1)
        XCTAssertEqual(BondLevel(minutes: 60).level, 2)
        XCTAssertEqual(BondLevel(minutes: 180).level, 3)
        XCTAssertEqual(BondLevel(minutes: 600).level, 5)
        XCTAssertEqual(BondLevel(minutes: 120).minutesToNext, 60)
        XCTAssertEqual(BondLevel(minutes: 120).progress, 0.5, accuracy: 0.001)
    }
}

final class ScheduleTests: XCTestCase {
    private func date(weekday: Int, hour: Int, minute: Int = 0) -> Date {
        // Find a date this week with the given weekday.
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        while cal.component(.weekday, from: day) != weekday { day = cal.date(byAdding: .day, value: 1, to: day)! }
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    func testWeekdaySchedule() {
        let work = BlockSchedule(name: "Work", symbol: "briefcase.fill", startMinutes: 9 * 60, endMinutes: 17 * 60, weekdays: [2, 3, 4, 5, 6])
        XCTAssertTrue(work.isActive(at: date(weekday: 2, hour: 10)))
        XCTAssertFalse(work.isActive(at: date(weekday: 2, hour: 17)))
        XCTAssertFalse(work.isActive(at: date(weekday: 1, hour: 10)))
        XCTAssertEqual(work.daysText, "Weekdays")
    }

    func testOvernightScheduleBelongsToStartDay() {
        let bed = BlockSchedule(name: "Bed", symbol: "moon.fill", startMinutes: 22 * 60 + 30, endMinutes: 7 * 60, weekdays: [6]) // Friday night only
        XCTAssertTrue(bed.crossesMidnight)
        XCTAssertTrue(bed.isActive(at: date(weekday: 6, hour: 23)))
        XCTAssertTrue(bed.isActive(at: date(weekday: 7, hour: 6)))      // Saturday morning, still Friday's block
        XCTAssertFalse(bed.isActive(at: date(weekday: 7, hour: 23)))    // Saturday night isn't selected
        XCTAssertFalse(bed.isActive(at: date(weekday: 6, hour: 6)))     // Friday morning belongs to Thursday
    }

    func testDisabledScheduleIsNeverActive() {
        var s = BlockSchedule(name: "X", symbol: "clock", startMinutes: 0, endMinutes: 23 * 60, weekdays: [1, 2, 3, 4, 5, 6, 7])
        s.isEnabled = false
        XCTAssertFalse(s.isActive())
    }
}

final class SessionTests: XCTestCase {
    func testRemainingAndProgress() {
        let start = Date().addingTimeInterval(-10 * 60)
        let s = ActiveSession(minutes: 25, mascot: .orbit, start: start)
        XCTAssertEqual(s.remaining(), 15 * 60, accuracy: 1)
        XCTAssertEqual(s.progress(), 0.4, accuracy: 0.01)
        XCTAssertFalse(s.isFinished())
    }

    func testPausedSessionFreezes() {
        var s = ActiveSession(minutes: 25, mascot: .orbit, start: Date().addingTimeInterval(-5 * 60))
        s.pausedAt = Date().addingTimeInterval(-60)   // paused a minute ago at 21 minutes left
        XCTAssertEqual(s.remaining(), 21 * 60, accuracy: 1)
        XCTAssertEqual(s.remaining(at: Date().addingTimeInterval(3600)), 21 * 60, accuracy: 1)
        XCTAssertFalse(s.isFinished(at: Date().addingTimeInterval(3600)))
    }

    func testFinished() {
        let s = ActiveSession(minutes: 5, mascot: .leaf, start: Date().addingTimeInterval(-6 * 60))
        XCTAssertTrue(s.isFinished())
        XCTAssertEqual(s.remaining(), 0)
        XCTAssertEqual(s.progress(), 1)
    }

    func testMinimumLengthIsOneMinute() {
        let s = ActiveSession(minutes: 0, mascot: .orbit)
        XCTAssertEqual(s.plannedSeconds, 60)
    }
}

final class PersistenceTests: XCTestCase {
    func testOldSettingsFilesDecodeWithDefaults() throws {
        let json = #"{"dailyGoalMinutes": 45}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(AppSettings.self, from: json)
        XCTAssertEqual(settings.dailyGoalMinutes, 45)
        XCTAssertEqual(settings.defaultSessionMinutes, AppSettings().defaultSessionMinutes)
        XCTAssertTrue(settings.hapticsEnabled)
    }

    func testProfileIgnoresUnknownEnumValues() throws {
        let json = #"{"name": "Sam", "mascot": "dragon", "struggles": ["scrolling"]}"#.data(using: .utf8)!
        let profile = try JSONDecoder().decode(UserProfile.self, from: json)
        XCTAssertEqual(profile.name, "Sam")
        XCTAssertEqual(profile.mascot, .orbit)
        XCTAssertEqual(profile.struggles, [.scrolling])
    }

    func testSnapshotRoundTrip() throws {
        let data = try SharedFile<CrewSnapshot>.encoder.encode(CrewSnapshot.placeholder)
        let back = try SharedFile<CrewSnapshot>.decoder.decode(CrewSnapshot.self, from: data)
        XCTAssertEqual(back.name, CrewSnapshot.placeholder.name)
        XCTAssertEqual(back.weekMinutes, CrewSnapshot.placeholder.weekMinutes)
    }

    func testFormat() {
        XCTAssertEqual(Format.clock(25 * 60), "25:00")
        XCTAssertEqual(Format.clock(3725), "1:02:05")
        XCTAssertEqual(Format.duration(minutes: 90), "1h 30m")
        XCTAssertEqual(Format.duration(minutes: 45), "45m")
        XCTAssertEqual(Format.longDuration(minutes: 120), "2 hr")
    }

    func testEveryMascotHasLines() {
        for m in Mascot.allCases {
            XCTAssertFalse(m.greetings.isEmpty)
            XCTAssertFalse(m.encouragements.isEmpty)
            XCTAssertFalse(m.completions.isEmpty)
            XCTAssertFalse(m.gaveUpLines.isEmpty)
            XCTAssertFalse(m.breakLines.isEmpty)
            XCTAssertEqual(m.asset(.happy), "\(m.rawValue)_happy")
        }
    }
}
