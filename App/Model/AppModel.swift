import Foundation
import Observation
import SwiftUI
import UserNotifications
import WidgetKit

enum AppTab: String, Hashable {
    case focus, blocks, insights, crew
}

/// What the completion screen shows after a finished session.
struct CompletionSummary: Identifiable, Equatable {
    let id = UUID()
    let record: FocusSessionRecord
    let bondBefore: BondLevel
    let bondAfter: BondLevel
    let streak: Int
    let todaySeconds: Int
    let goalMinutes: Int
    let newAchievements: [Achievement]
    let line: String

    var leveledUp: Bool { bondAfter.level > bondBefore.level }
}

/// The single source of truth for the iPhone app.
@MainActor
@Observable
final class AppModel {
    static let shared = AppModel()

    // Persistent state
    var profile: UserProfile
    var settings: AppSettings
    var history: [FocusSessionRecord]
    var schedules: [BlockSchedule]
    var active: ActiveSession?
    var unlocked: [String: Date]

    // Presentation state
    var selectedTab: AppTab = .focus
    var showSession = false
    var completion: CompletionSummary?
    var abandoned: FocusSessionRecord?
    var toast: String?

    let screenTime = ScreenTimeService()
    let sounds = SoundPlayer()
    let purchases = PurchaseManager()

    @ObservationIgnored private var ticker: Task<Void, Never>?
    @ObservationIgnored var isDemo = false
    @ObservationIgnored private var didBootstrap = false

    init() {
        profile = SharedFiles.profile.load() ?? UserProfile()
        settings = SharedFiles.settings.load() ?? AppSettings()
        history = SharedFiles.history.load() ?? []
        schedules = SharedFiles.schedules.load() ?? []
        active = SharedFiles.activeSession.load()
        unlocked = SharedFiles.unlocked.load() ?? [:]
        Haptics.isEnabled = settings.hapticsEnabled
    }

    // MARK: Derived

    var hasOnboarded: Bool { profile.onboardedAt != nil }
    var mascot: Mascot { profile.mascot }
    var stats: FocusStats { FocusStats(history: history) }
    var todaySeconds: Int { stats.focusSeconds(on: Date()) }
    var streak: Int { stats.currentStreak() }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hello, night owl"
        }
    }

    var nextSchedule: (schedule: BlockSchedule, startsAt: Date)? {
        let cal = Calendar.current
        let now = Date()
        var best: (BlockSchedule, Date)?
        for s in schedules where s.isEnabled {
            for dayOffset in 0..<8 {
                guard let day = cal.date(byAdding: .day, value: dayOffset, to: cal.startOfDay(for: now)),
                      let start = cal.date(bySettingHour: s.startMinutes / 60, minute: s.startMinutes % 60, second: 0, of: day),
                      start > now, s.startsOn(weekday: cal.component(.weekday, from: start)) else { continue }
                if best == nil || start < best!.1 { best = (s, start) }
                break
            }
        }
        return best.map { (schedule: $0.0, startsAt: $0.1) }
    }

    var activeSchedule: BlockSchedule? { schedules.first { $0.isActive() } }

    // MARK: Lifecycle

    func bootstrap() {
        guard !didBootstrap else { return }
        didBootstrap = true
        IntentBridge.startFocus = { minutes in AppModel.shared.quickStart(minutes: minutes) }
        IntentBridge.pause = { AppModel.shared.pause() }
        IntentBridge.resume = { AppModel.shared.resume() }
        IntentBridge.end = { AppModel.shared.endFromOutside() }
        NotificationDelegate.shared.onOpenLink = { url in AppModel.shared.handle(url) }
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        purchases.start()
        reconcile()
    }

    /// Called on launch and whenever the app comes to the foreground.
    func reconcile() {
        guard !isDemo else { return }
        screenTime.refreshStatus()
        if let disk = SharedFiles.activeSession.load() { active = disk }
        if let s = active {
            if s.isFinished(at: Date()) {
                finishActive(completed: true)
            } else {
                startTicking()
                if s.blocking && screenTime.isAuthorized && !s.isPaused { screenTime.beginFocus(s) }
            }
        }
        if screenTime.isAuthorized {
            for schedule in schedules { Shields.refresh(schedule: schedule) }
        }
        refreshReminders()
        publish()
    }

    // MARK: Focus sessions

    func quickStart(minutes: Int?) {
        guard hasOnboarded else { return }
        if active == nil {
            startFocus(
                minutes: minutes ?? settings.defaultSessionMinutes,
                intention: "",
                strict: settings.strictByDefault,
                block: settings.blockDuringFocus
            )
        }
        showSession = true
    }

    func startFocus(minutes: Int, intention: String, strict: Bool, block: Bool) {
        guard active == nil else { showSession = true; return }
        let selection = screenTime.focusSelection
        let blocking = block && screenTime.isAuthorized && !selection.isEmptySelection
        let session = ActiveSession(
            kind: .focus,
            minutes: minutes,
            mascot: mascot,
            intention: intention.trimmingCharacters(in: .whitespacesAndNewlines),
            strict: strict,
            blocking: blocking,
            blockedItems: blocking ? selection.itemCount : 0
        )
        begin(session)
    }

    func startBreak(minutes: Int? = nil) {
        guard active == nil else { return }
        let session = ActiveSession(kind: .rest, minutes: minutes ?? settings.breakMinutes, mascot: mascot)
        completion = nil
        begin(session)
    }

    private func begin(_ session: ActiveSession) {
        active = session
        saveActive()
        if session.blocking { screenTime.beginFocus(session) }
        LiveActivityController.start(session, enabled: settings.liveActivitiesEnabled && !isDemo)
        if !isDemo { Notifications.scheduleSessionEnd(session, enabled: settings.sessionEndAlerts) }
        if session.kind == .focus && settings.ambientSound != .off && !isDemo {
            sounds.playAmbient(settings.ambientSound, volume: settings.ambientVolume)
        }
        Haptics.medium()
        showSession = true
        startTicking()
        publish()
    }

    func pause() {
        guard var s = active, !s.isPaused, s.kind == .focus, !s.strict else { return }
        s.pausedAt = Date()
        active = s
        saveActive()
        if s.blocking { screenTime.liftFocusShields() }
        Notifications.cancelSessionEnd()
        LiveActivityController.update(s)
        sounds.pauseAmbient()
        Haptics.soft()
        publish()
    }

    func resume() {
        guard var s = active, let pausedAt = s.pausedAt else { return }
        let pausedFor = Date().timeIntervalSince(pausedAt)
        s.pausedSeconds += pausedFor
        s.endsAt = s.endsAt.addingTimeInterval(pausedFor)
        s.pausedAt = nil
        active = s
        saveActive()
        if s.blocking { screenTime.beginFocus(s) }
        Notifications.scheduleSessionEnd(s, enabled: settings.sessionEndAlerts)
        LiveActivityController.update(s)
        sounds.resumeAmbient()
        Haptics.medium()
        startTicking()
        publish()
    }

    /// Give up before the timer ends.
    func endEarly() {
        finishActive(completed: false)
    }

    /// Ending from the Live Activity: strict sessions can't be ended from outside the app.
    func endFromOutside() {
        guard let s = active else { return }
        if s.strict && s.kind == .focus {
            showSession = true
            return
        }
        finishActive(completed: s.kind == .rest)
    }

    func extend(byMinutes minutes: Int) {
        guard var s = active, !s.isPaused else { return }
        s.endsAt = s.endsAt.addingTimeInterval(TimeInterval(minutes * 60))
        s.plannedSeconds += minutes * 60
        active = s
        saveActive()
        if s.blocking { screenTime.beginFocus(s) }
        Notifications.scheduleSessionEnd(s, enabled: settings.sessionEndAlerts)
        LiveActivityController.update(s)
        publish()
    }

    private func startTicking() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self else { return }
                self.tick()
            }
        }
    }

    private func tick() {
        guard let s = active else {
            ticker?.cancel()
            return
        }
        if s.isFinished(at: Date()) { finishActive(completed: true) }
    }

    private func finishActive(completed: Bool) {
        guard let s = active else { return }
        ticker?.cancel()
        let now = Date()
        let focused = completed ? s.plannedSeconds : Int(s.elapsed(at: now))
        let record = FocusSessionRecord(
            startedAt: s.startedAt,
            endedAt: completed ? min(now, s.endsAt) : now,
            plannedSeconds: s.plannedSeconds,
            focusedSeconds: focused,
            completed: completed,
            mascot: s.mascot,
            intention: s.intention,
            strict: s.strict,
            kind: s.kind
        )
        let bondBefore = stats.bond(with: s.mascot)
        if s.kind == .focus && (completed || focused >= 60) {
            history.append(record)
            saveHistory()
        }
        active = nil
        saveActive()
        if s.blocking { screenTime.liftFocusShields() }
        if !completed { Notifications.cancelSessionEnd() }
        LiveActivityController.finish(s, completed: completed)
        sounds.stopAmbient()

        if s.kind == .focus {
            if completed {
                if settings.chimeEnabled { sounds.playChime() }
                Haptics.success()
                let newOnes = checkAchievements()
                let st = stats
                completion = CompletionSummary(
                    record: record,
                    bondBefore: bondBefore,
                    bondAfter: st.bond(with: s.mascot),
                    streak: st.currentStreak(),
                    todaySeconds: st.focusSeconds(on: now),
                    goalMinutes: settings.dailyGoalMinutes,
                    newAchievements: newOnes,
                    line: s.mascot.line(from: s.mascot.completions, seed: history.count)
                )
                showSession = true
            } else {
                showSession = false
                abandoned = record
                Haptics.warning()
            }
        } else {
            showSession = false
            if completed {
                if settings.chimeEnabled { sounds.playChime(named: "nudge") }
                toast = "Break's over. Ready for another round?"
            }
        }
        refreshReminders()
        publish()
    }

    // MARK: Achievements

    func isUnlocked(_ a: Achievement) -> Bool { unlocked[a.rawValue] != nil }

    @discardableResult
    func checkAchievements() -> [Achievement] {
        let st = stats
        let earned = Achievement.allCases.filter {
            $0.isUnlocked(stats: st, dailyGoalMinutes: settings.dailyGoalMinutes, scheduleCount: schedules.count)
        }
        let newOnes = earned.filter { unlocked[$0.rawValue] == nil }
        guard !newOnes.isEmpty else { return [] }
        for a in newOnes { unlocked[a.rawValue] = Date() }
        if !isDemo { SharedFiles.unlocked.save(unlocked) }
        return newOnes
    }

    // MARK: Profile & settings

    func updateSettings(_ change: (inout AppSettings) -> Void) {
        let before = settings
        change(&settings)
        guard settings != before else { return }
        Haptics.isEnabled = settings.hapticsEnabled
        saveSettings()
        if before.dailyReminderEnabled != settings.dailyReminderEnabled
            || before.dailyReminderMinutes != settings.dailyReminderMinutes
            || before.streakReminderEnabled != settings.streakReminderEnabled {
            refreshReminders()
        }
        if before.ambientVolume != settings.ambientVolume { sounds.setVolume(settings.ambientVolume) }
        publish()
    }

    func updateProfile(_ change: (inout UserProfile) -> Void) {
        change(&profile)
        saveProfile()
        publish()
    }

    func choose(mascot: Mascot) {
        guard mascot != profile.mascot else { return }
        updateProfile { $0.mascot = mascot }
        Haptics.success()
        refreshReminders()
    }

    func finishOnboarding() {
        updateProfile { $0.onboardedAt = Date() }
        if settings.defaultSessionMinutes <= 0 { updateSettings { $0.defaultSessionMinutes = 25 } }
        refreshReminders()
        selectedTab = .focus
        toast = "Welcome to the crew, \(profile.firstName)!"
    }

    func resetEverything() {
        if let s = active, s.blocking { screenTime.liftFocusShields() }
        screenTime.removeAllBlocking()
        screenTime.setFocusSelection(.init())
        Notifications.removeAll()
        Task { await LiveActivityController.endAll(immediately: true) }
        sounds.stopAmbient()
        ticker?.cancel()
        profile = UserProfile()
        settings = AppSettings()
        history = []
        schedules = []
        active = nil
        unlocked = [:]
        completion = nil
        showSession = false
        for file in [SharedFiles.profile.url, SharedFiles.settings.url, SharedFiles.history.url, SharedFiles.schedules.url,
                     SharedFiles.activeSession.url, SharedFiles.unlocked.url, SharedFiles.snapshot.url] {
            try? FileManager.default.removeItem(at: file)
        }
        publish()
    }

    // MARK: Schedules

    func save(schedule: BlockSchedule) {
        if let i = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[i] = schedule
        } else {
            schedules.append(schedule)
        }
        schedulesChanged()
        if let new = checkAchievements().first { toast = "Badge unlocked: \(new.title)" }
    }

    func delete(schedule: BlockSchedule) {
        schedules.removeAll { $0.id == schedule.id }
        Shields.clear(.schedule(schedule.id))
        schedulesChanged()
    }

    func toggle(schedule: BlockSchedule, on: Bool) {
        guard let i = schedules.firstIndex(where: { $0.id == schedule.id }) else { return }
        schedules[i].isEnabled = on
        schedulesChanged()
    }

    private func schedulesChanged() {
        saveSchedules()
        screenTime.sync(schedules: schedules)
        publish()
    }

    // MARK: Reminders

    func refreshReminders() {
        guard !isDemo, hasOnboarded else { return }
        Notifications.scheduleDailyReminder(enabled: settings.dailyReminderEnabled, minutes: settings.dailyReminderMinutes, mascot: mascot)
        Notifications.scheduleStreakSaver(
            enabled: settings.streakReminderEnabled,
            focusedToday: todaySeconds > 0,
            streak: streak,
            mascot: mascot
        )
    }

    // MARK: Deep links

    func handle(_ url: URL) {
        guard url.scheme == "focuscrew" else { return }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        switch url.host {
        case "start":
            let minutes = items.first { $0.name == "minutes" }?.value.flatMap(Int.init)
            quickStart(minutes: minutes)
        case "break":
            if active == nil { startBreak() }
        case "session":
            if active != nil || completion != nil { showSession = true }
        case "blocks":
            selectedTab = .blocks
        case "insights":
            selectedTab = .insights
        case "crew":
            selectedTab = .crew
        default:
            selectedTab = .focus
            if active != nil { showSession = true }
        }
    }

    // MARK: Persistence

    private func saveProfile() { if !isDemo { SharedFiles.profile.save(profile) } }
    private func saveSettings() { if !isDemo { SharedFiles.settings.save(settings) } }
    private func saveHistory() { if !isDemo { SharedFiles.history.save(history) } }
    private func saveSchedules() { if !isDemo { SharedFiles.schedules.save(schedules) } }
    private func saveActive() { if !isDemo { SharedFiles.activeSession.save(active) } }

    func makeSnapshot() -> CrewSnapshot {
        let st = stats
        return CrewSnapshot(
            name: profile.firstName,
            mascot: mascot,
            active: active,
            todayFocusSeconds: st.focusSeconds(on: Date()),
            dailyGoalMinutes: settings.dailyGoalMinutes,
            streak: st.currentStreak(),
            weekMinutes: st.dailyMinutes(lastDays: 7).map(\.minutes),
            totalSessions: st.completedCount,
            totalFocusSeconds: st.totalFocusSeconds,
            defaultMinutes: settings.defaultSessionMinutes,
            updatedAt: Date()
        )
    }

    /// Pushes the latest state to widgets, the shield extension and the Mac.
    func publish() {
        guard !isDemo else { return }
        let snapshot = makeSnapshot()
        SharedFiles.snapshot.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
        CloudBridge.publish(snapshot, enabled: settings.syncToMac)
    }
}
