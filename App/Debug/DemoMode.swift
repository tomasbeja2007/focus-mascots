#if DEBUG
import SwiftUI

/// Debug-only screenshot mode. Launch with `-demoScreen <name>` (see ci/screens.txt)
/// to open a screen with sample data. Nothing is written to disk in demo mode.
enum DemoMode {
    static var screen: String? {
        let value = UserDefaults.standard.string(forKey: "demoScreen")
        return (value?.isEmpty ?? true) ? nil : value
    }

    @MainActor
    static func prepare(_ model: AppModel) {
        guard let screen else { return }
        model.isDemo = true
        model.screenTime.demoAuthorized = !screen.hasPrefix("ob-") && screen != "blocks-empty"

        var profile = UserProfile()
        profile.name = "Alex"
        profile.age = .age25to34
        profile.role = .professional
        profile.dailyScreenHours = 6
        profile.struggles = [.scrolling, .focus, .sleep]
        profile.timeSinks = [.social, .shortVideo, .news]
        profile.hardestTimes = [.workday, .bedtime]
        profile.focusSpan = .from15to30
        profile.goal = .deepWork
        profile.motivation = .gentle
        profile.mascot = .orbit
        profile.matchedMascot = .orbit
        profile.onboardedAt = screen.hasPrefix("ob-") ? nil : Date()
        profile.createdAt = Date().addingTimeInterval(-40 * 86_400)
        model.profile = profile

        var settings = AppSettings()
        settings.dailyGoalMinutes = 90
        settings.defaultSessionMinutes = 25
        settings.ambientSound = .rain
        model.settings = settings

        model.history = sampleHistory()
        model.schedules = sampleSchedules()
        var unlocked: [String: Date] = [:]
        for a in [Achievement.firstSession, .streak3, .hour1, .hours10, .earlyBird, .goalGetter, .planner, .weekend] {
            unlocked[a.rawValue] = Date().addingTimeInterval(-Double.random(in: 1...20) * 86_400)
        }
        model.unlocked = unlocked

        switch screen {
        case "blocks", "schedule-editor": model.selectedTab = .blocks
        case "insights": model.selectedTab = .insights
        case "crew": model.selectedTab = .crew
        default: model.selectedTab = .focus
        }

        if screen == "session" || screen == "session-paused" {
            var s = ActiveSession(kind: .focus, minutes: 25, mascot: .orbit, intention: "Finish the quarterly report", strict: false, blocking: true, blockedItems: 9, start: Date().addingTimeInterval(-6 * 60 - 18))
            if screen == "session-paused" { s.pausedAt = Date() }
            model.active = s
        }
    }

    static func sampleHistory() -> [FocusSessionRecord] {
        var generator = SeededGenerator(seed: 42)
        let cal = Calendar.current
        let intentions = ["Quarterly report", "Deep work", "Read 30 pages", "Design review", "Inbox zero", "Study Spanish", "", "Write blog post", ""]
        var records: [FocusSessionRecord] = []
        for dayOffset in (0...27).reversed() {
            guard let day = cal.date(byAdding: .day, value: -dayOffset, to: cal.startOfDay(for: Date())) else { continue }
            let skip = dayOffset > 7 && Int.random(in: 0..<10, using: &generator) < 2
            if skip { continue }
            let count = dayOffset == 0 ? 2 : Int.random(in: 1...4, using: &generator)
            var hour = Int.random(in: 7...10, using: &generator)
            for _ in 0..<count {
                let minutes = [15, 25, 25, 45, 50, 60][Int.random(in: 0..<6, using: &generator)]
                guard let start = cal.date(bySettingHour: min(hour, 22), minute: Int.random(in: 0..<50, using: &generator), second: 0, of: day) else { continue }
                if dayOffset == 0 && start > Date() { continue }
                let completed = Int.random(in: 0..<10, using: &generator) < 9
                let focused = completed ? minutes * 60 : Int.random(in: 5..<minutes, using: &generator) * 60
                let mascot: Mascot = dayOffset < 14 ? .orbit : Mascot.allCases[Int.random(in: 0..<5, using: &generator)]
                records.append(FocusSessionRecord(
                    startedAt: start,
                    endedAt: start.addingTimeInterval(TimeInterval(focused)),
                    plannedSeconds: minutes * 60,
                    focusedSeconds: focused,
                    completed: completed,
                    mascot: mascot,
                    intention: intentions[Int.random(in: 0..<intentions.count, using: &generator)],
                    strict: Int.random(in: 0..<5, using: &generator) == 0
                ))
                hour += Int.random(in: 1...3, using: &generator)
            }
        }
        return records
    }

    static func sampleSchedules() -> [BlockSchedule] {
        var work = BlockSchedule.templates[0]
        work.appCount = 8
        work.categoryCount = 2
        var bed = BlockSchedule.templates[2]
        bed.appCount = 12
        bed.categoryCount = 3
        var study = BlockSchedule.templates[1]
        study.isEnabled = false
        study.appCount = 5
        return [work, bed, study]
    }

    static var sampleCompletion: CompletionSummary {
        let record = FocusSessionRecord(startedAt: Date().addingTimeInterval(-25 * 60), endedAt: Date(), plannedSeconds: 25 * 60, focusedSeconds: 25 * 60, completed: true, mascot: .orbit, intention: "Finish the quarterly report")
        return CompletionSummary(
            record: record,
            bondBefore: BondLevel(minutes: 330),
            bondAfter: BondLevel(minutes: 355),
            streak: 7,
            todaySeconds: 75 * 60,
            goalMinutes: 90,
            newAchievements: [.streak7],
            line: Mascot.orbit.completions[0]
        )
    }

    static var sampleDraft: UserProfile {
        var p = UserProfile()
        p.name = "Alex"
        p.age = .age25to34
        p.role = .professional
        p.dailyScreenHours = 6
        p.struggles = [.scrolling, .focus]
        p.timeSinks = [.social, .shortVideo, .news]
        p.hardestTimes = [.bedtime]
        p.focusSpan = .from15to30
        p.goal = .deepWork
        p.motivation = .gentle
        p.mascot = .orbit
        p.matchedMascot = .orbit
        return p
    }
}

/// Deterministic random numbers so screenshots are stable.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 0x9E37_79B9_7F4A_7C15 | 1 }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

/// Picks the view for a demo screen name.
struct DemoScreenView: View {
    @Environment(AppModel.self) private var model
    let screen: String

    var body: some View {
        switch screen {
        case "ob-welcome": OnboardingFlow(start: .welcome, draft: DemoMode.sampleDraft)
        case "ob-intro": OnboardingFlow(start: .introFocus, draft: DemoMode.sampleDraft)
        case "ob-name": OnboardingFlow(start: .name, draft: DemoMode.sampleDraft)
        case "ob-question": OnboardingFlow(start: .focusSpan, draft: DemoMode.sampleDraft)
        case "ob-multi": OnboardingFlow(start: .struggles, draft: DemoMode.sampleDraft)
        case "ob-slider": OnboardingFlow(start: .screenTime, draft: DemoMode.sampleDraft)
        case "ob-reality": OnboardingFlow(start: .reality, draft: DemoMode.sampleDraft)
        case "ob-analyzing": OnboardingFlow(start: .analyzing, draft: DemoMode.sampleDraft)
        case "ob-reveal": OnboardingFlow(start: .reveal, draft: DemoMode.sampleDraft)
        case "ob-plan": OnboardingFlow(start: .plan, draft: DemoMode.sampleDraft)
        case "ob-goal": OnboardingFlow(start: .dailyGoal, draft: DemoMode.sampleDraft)
        case "ob-screentime": OnboardingFlow(start: .screenTimePermission, draft: DemoMode.sampleDraft)
        case "ob-apps": OnboardingFlow(start: .chooseApps, draft: DemoMode.sampleDraft)
        case "ob-notifications": OnboardingFlow(start: .notifications, draft: DemoMode.sampleDraft)
        case "ob-pledge": OnboardingFlow(start: .pledge, draft: DemoMode.sampleDraft)
        case "ob-paywall": OnboardingFlow(start: .paywall, draft: DemoMode.sampleDraft)
        case "session", "session-paused":
            if let s = model.active { ActiveSessionView(session: s) } else { MainTabView() }
        case "complete":
            CompletionView(summary: DemoMode.sampleCompletion)
        case "schedule-editor":
            ScheduleEditorView(schedule: DemoMode.sampleSchedules()[0], isNew: false)
        case "mascot-detail":
            MascotDetailView(mascot: .spark)
        case "achievements":
            NavigationStack { AchievementsView() }
        case "settings":
            SettingsView()
        case "widgets":
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Widgets").font(.rounded(.largeTitle, weight: .bold)).foregroundStyle(Theme.ink)
                    WidgetGallery(snapshot: model.makeSnapshot())
                }
                .padding(Theme.pagePadding)
            }
            .pageBackground()
        case "live-activity":
            ZStack {
                LinearGradient(colors: [Color(red: 0.36, green: 0.45, blue: 0.68), Color(red: 0.62, green: 0.5, blue: 0.72)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    Text(Date().formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 76, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    LiveActivityGallery(mascot: .orbit)
                        .padding(.horizontal, 12)
                    Spacer()
                }
                .padding(.top, 20)
            }
        default:
            MainTabView()
        }
    }
}
#endif
