import Foundation

/// A single answer option shown in onboarding.
protocol QuizOption: CaseIterable, Identifiable, Hashable, Codable, RawRepresentable where RawValue == String {
    var title: String { get }
    var symbol: String { get }
    /// How strongly this answer points to each mascot.
    var weights: [Mascot: Double] { get }
}

extension QuizOption {
    var id: String { rawValue }
}

enum AgeRange: String, QuizOption {
    case under18, age18to24, age25to34, age35to44, age45to54, age55plus

    var title: String {
        switch self {
        case .under18: return "Under 18"
        case .age18to24: return "18 – 24"
        case .age25to34: return "25 – 34"
        case .age35to44: return "35 – 44"
        case .age45to54: return "45 – 54"
        case .age55plus: return "55 or older"
        }
    }

    var symbol: String { "person.fill" }

    var midAge: Double {
        switch self {
        case .under18: return 16
        case .age18to24: return 21
        case .age25to34: return 30
        case .age35to44: return 40
        case .age45to54: return 50
        case .age55plus: return 60
        }
    }

    var weights: [Mascot: Double] {
        switch self {
        case .under18, .age18to24: return [.spark: 1]
        case .age25to34: return [.orbit: 0.5]
        case .age35to44: return [.orbit: 0.5, .blob: 0.5]
        case .age45to54, .age55plus: return [.leaf: 1]
        }
    }
}

enum LifeRole: String, QuizOption {
    case student, professional, creator, founder, parent, other

    var title: String {
        switch self {
        case .student: return "Student"
        case .professional: return "Working professional"
        case .creator: return "Creator or freelancer"
        case .founder: return "Founder or business owner"
        case .parent: return "Parent or caregiver"
        case .other: return "Something else"
        }
    }

    var symbol: String {
        switch self {
        case .student: return "graduationcap.fill"
        case .professional: return "briefcase.fill"
        case .creator: return "paintbrush.pointed.fill"
        case .founder: return "lightbulb.fill"
        case .parent: return "figure.and.child.holdinghands"
        case .other: return "sparkles"
        }
    }

    var weights: [Mascot: Double] {
        switch self {
        case .student: return [.orbit: 1, .spark: 1]
        case .professional: return [.orbit: 1.5]
        case .creator: return [.spark: 1.5]
        case .founder: return [.pebble: 1, .blob: 1]
        case .parent: return [.leaf: 1.5]
        case .other: return [:]
        }
    }
}

enum Struggle: String, QuizOption {
    case scrolling, procrastination, focus, sleep, notifications, motivation, multitasking, breaks

    var title: String {
        switch self {
        case .scrolling: return "Endless scrolling"
        case .procrastination: return "Procrastinating"
        case .focus: return "Staying focused"
        case .sleep: return "Phone in bed at night"
        case .notifications: return "Constant notifications"
        case .motivation: return "Low motivation"
        case .multitasking: return "Jumping between apps"
        case .breaks: return "Forgetting to take breaks"
        }
    }

    var symbol: String {
        switch self {
        case .scrolling: return "arrow.down.circle.fill"
        case .procrastination: return "hourglass"
        case .focus: return "scope"
        case .sleep: return "bed.double.fill"
        case .notifications: return "bell.badge.fill"
        case .motivation: return "battery.25percent"
        case .multitasking: return "square.on.square"
        case .breaks: return "cup.and.saucer.fill"
        }
    }

    var weights: [Mascot: Double] {
        switch self {
        case .scrolling: return [.pebble: 2, .orbit: 0.5]
        case .procrastination: return [.spark: 2.5]
        case .focus: return [.orbit: 2.5]
        case .sleep: return [.leaf: 2.5]
        case .notifications: return [.orbit: 1, .pebble: 1]
        case .motivation: return [.spark: 2, .blob: 0.5]
        case .multitasking: return [.orbit: 1.5, .pebble: 0.5]
        case .breaks: return [.leaf: 2]
        }
    }
}

enum TimeSink: String, QuizOption {
    case social, shortVideo, streaming, games, news, shopping, messaging, work

    var title: String {
        switch self {
        case .social: return "Social media"
        case .shortVideo: return "Short videos"
        case .streaming: return "YouTube & streaming"
        case .games: return "Games"
        case .news: return "News & Reddit"
        case .shopping: return "Shopping"
        case .messaging: return "Messaging"
        case .work: return "Email & work chat"
        }
    }

    var symbol: String {
        switch self {
        case .social: return "person.2.fill"
        case .shortVideo: return "play.rectangle.on.rectangle.fill"
        case .streaming: return "tv.fill"
        case .games: return "gamecontroller.fill"
        case .news: return "newspaper.fill"
        case .shopping: return "bag.fill"
        case .messaging: return "bubble.left.and.bubble.right.fill"
        case .work: return "envelope.fill"
        }
    }

    var weights: [Mascot: Double] {
        switch self {
        case .social, .shortVideo: return [.pebble: 1]
        case .streaming: return [.leaf: 0.5, .pebble: 0.5]
        case .games: return [.spark: 0.5, .pebble: 0.5]
        case .news: return [.leaf: 0.5]
        case .shopping: return [.blob: 0.5]
        case .messaging: return [.orbit: 0.5]
        case .work: return [.orbit: 1]
        }
    }
}

enum DayPart: String, QuizOption {
    case morning, workday, afternoon, evening, bedtime

    var title: String {
        switch self {
        case .morning: return "Right after waking up"
        case .workday: return "During work or class"
        case .afternoon: return "The afternoon slump"
        case .evening: return "Evenings at home"
        case .bedtime: return "In bed before sleep"
        }
    }

    var symbol: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .workday: return "laptopcomputer"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sofa.fill"
        case .bedtime: return "moon.stars.fill"
        }
    }

    var weights: [Mascot: Double] {
        switch self {
        case .morning: return [.spark: 1]
        case .workday: return [.orbit: 1]
        case .afternoon: return [.spark: 1]
        case .evening: return [.blob: 0.5, .leaf: 0.5]
        case .bedtime: return [.leaf: 1.5]
        }
    }
}

enum FocusSpan: String, QuizOption {
    case under5, from5to15, from15to30, from30to60, over60

    var title: String {
        switch self {
        case .under5: return "Less than 5 minutes"
        case .from5to15: return "5 – 15 minutes"
        case .from15to30: return "15 – 30 minutes"
        case .from30to60: return "30 – 60 minutes"
        case .over60: return "More than an hour"
        }
    }

    var symbol: String {
        switch self {
        case .under5: return "gauge.with.dots.needle.0percent"
        case .from5to15: return "gauge.with.dots.needle.33percent"
        case .from15to30: return "gauge.with.dots.needle.50percent"
        case .from30to60: return "gauge.with.dots.needle.67percent"
        case .over60: return "gauge.with.dots.needle.100percent"
        }
    }

    var weights: [Mascot: Double] {
        switch self {
        case .under5, .from5to15: return [.spark: 1.5]
        case .from15to30: return [.orbit: 1]
        case .from30to60: return [.orbit: 0.5, .pebble: 0.5]
        case .over60: return [.pebble: 1]
        }
    }

    /// A session length that stretches the user a little, without overwhelming them.
    var suggestedSessionMinutes: Int {
        switch self {
        case .under5: return 10
        case .from5to15: return 15
        case .from15to30: return 25
        case .from30to60: return 45
        case .over60: return 60
        }
    }

    var suggestedDailyGoalMinutes: Int {
        switch self {
        case .under5: return 45
        case .from5to15: return 60
        case .from15to30: return 90
        case .from30to60: return 120
        case .over60: return 180
        }
    }
}

enum MainGoal: String, QuizOption {
    case deepWork, study, sleep, presence, habits, calm

    var title: String {
        switch self {
        case .deepWork: return "Do deep, focused work"
        case .study: return "Study and learn better"
        case .sleep: return "Sleep better"
        case .presence: return "Be present with people"
        case .habits: return "Build better habits"
        case .calm: return "Feel calmer, less anxious"
        }
    }

    var symbol: String {
        switch self {
        case .deepWork: return "brain.head.profile"
        case .study: return "book.fill"
        case .sleep: return "moon.zzz.fill"
        case .presence: return "heart.fill"
        case .habits: return "checkmark.seal.fill"
        case .calm: return "leaf.fill"
        }
    }

    var weights: [Mascot: Double] {
        switch self {
        case .deepWork: return [.orbit: 2]
        case .study: return [.orbit: 1, .blob: 1]
        case .sleep: return [.leaf: 2]
        case .presence: return [.leaf: 1, .pebble: 1]
        case .habits: return [.pebble: 1.5, .blob: 1]
        case .calm: return [.leaf: 1.5]
        }
    }
}

enum MotivationStyle: String, QuizOption {
    case gentle, toughLove, data, energy, calm

    var title: String {
        switch self {
        case .gentle: return "Gentle encouragement"
        case .toughLove: return "Tough love, no excuses"
        case .data: return "Stats, charts and streaks"
        case .energy: return "Hype and high energy"
        case .calm: return "Calm and quiet support"
        }
    }

    var symbol: String {
        switch self {
        case .gentle: return "hand.thumbsup.fill"
        case .toughLove: return "figure.strengthtraining.traditional"
        case .data: return "chart.bar.xaxis"
        case .energy: return "flame.fill"
        case .calm: return "wind"
        }
    }

    var weights: [Mascot: Double] {
        switch self {
        case .gentle: return [.orbit: 2]
        case .toughLove: return [.pebble: 3]
        case .data: return [.blob: 3]
        case .energy: return [.spark: 3]
        case .calm: return [.leaf: 3]
        }
    }

    var mascot: Mascot {
        switch self {
        case .gentle: return .orbit
        case .toughLove: return .pebble
        case .data: return .blob
        case .energy: return .spark
        case .calm: return .leaf
        }
    }
}

/// Everything the user told us during onboarding.
struct UserProfile: Codable, Equatable {
    var name: String = ""
    var age: AgeRange?
    var role: LifeRole?
    var dailyScreenHours: Double = 5
    var struggles: [Struggle] = []
    var timeSinks: [TimeSink] = []
    var hardestTimes: [DayPart] = []
    var focusSpan: FocusSpan?
    var goal: MainGoal?
    var motivation: MotivationStyle?
    var mascot: Mascot = .orbit
    var matchedMascot: Mascot?
    var onboardedAt: Date?
    var pledgedAt: Date?
    var createdAt: Date = Date()

    init() {}

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "friend" : trimmed
    }

    var firstName: String {
        displayName.split(separator: " ").first.map(String.init) ?? displayName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        age = try? c.decodeIfPresent(AgeRange.self, forKey: .age)
        role = try? c.decodeIfPresent(LifeRole.self, forKey: .role)
        dailyScreenHours = try c.decodeIfPresent(Double.self, forKey: .dailyScreenHours) ?? 5
        struggles = (try? c.decodeIfPresent([Struggle].self, forKey: .struggles)) ?? []
        timeSinks = (try? c.decodeIfPresent([TimeSink].self, forKey: .timeSinks)) ?? []
        hardestTimes = (try? c.decodeIfPresent([DayPart].self, forKey: .hardestTimes)) ?? []
        focusSpan = try? c.decodeIfPresent(FocusSpan.self, forKey: .focusSpan)
        goal = try? c.decodeIfPresent(MainGoal.self, forKey: .goal)
        motivation = try? c.decodeIfPresent(MotivationStyle.self, forKey: .motivation)
        mascot = (try? c.decodeIfPresent(Mascot.self, forKey: .mascot)) ?? .orbit
        matchedMascot = try? c.decodeIfPresent(Mascot.self, forKey: .matchedMascot)
        onboardedAt = try c.decodeIfPresent(Date.self, forKey: .onboardedAt)
        pledgedAt = try c.decodeIfPresent(Date.self, forKey: .pledgedAt)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

/// Picks the companion that fits the user's answers best.
enum MascotMatcher {
    struct Result {
        var mascot: Mascot
        var scores: [Mascot: Double]
        var reasons: [String]
    }

    static func match(_ p: UserProfile) -> Result {
        var scores: [Mascot: Double] = Dictionary(uniqueKeysWithValues: Mascot.allCases.map { ($0, 0) })
        func add(_ w: [Mascot: Double], _ factor: Double = 1) {
            for (m, v) in w { scores[m, default: 0] += v * factor }
        }
        if let a = p.age { add(a.weights, 0.5) }
        if let r = p.role { add(r.weights) }
        p.struggles.forEach { add($0.weights) }
        p.timeSinks.forEach { add($0.weights, 0.5) }
        p.hardestTimes.forEach { add($0.weights, 0.7) }
        if let s = p.focusSpan { add(s.weights) }
        if let g = p.goal { add(g.weights, 1.5) }
        if let m = p.motivation { add(m.weights, 1.5) }
        if p.dailyScreenHours >= 7 { add([.pebble: 1.5]) }

        let tieBreak = p.motivation?.mascot ?? .orbit
        let best = scores.max { a, b in
            if a.value == b.value { return a.key != tieBreak && b.key == tieBreak }
            return a.value < b.value
        }?.key ?? tieBreak
        return Result(mascot: best, scores: scores, reasons: reasons(for: best, p))
    }

    static func reasons(for m: Mascot, _ p: UserProfile) -> [String] {
        var out: [String] = []
        switch m {
        case .orbit:
            if p.struggles.contains(.focus) { out.append("You told us staying focused is hard. Orbit is built for deep work.") }
            if p.goal == .deepWork || p.goal == .study { out.append("You want to \(p.goal!.title.lowercased()). Orbit's sessions are made for exactly that.") }
            if p.motivation == .gentle { out.append("You like gentle encouragement. Orbit never nags.") }
        case .spark:
            if p.struggles.contains(.procrastination) { out.append("Procrastination is your nemesis. Spark makes starting easy.") }
            if p.struggles.contains(.motivation) { out.append("Low motivation? Spark brings the energy.") }
            if p.focusSpan == .under5 || p.focusSpan == .from5to15 { out.append("Short, winnable sprints fit your attention span right now.") }
            if p.motivation == .energy { out.append("You asked for hype. Spark has plenty.") }
        case .leaf:
            if p.struggles.contains(.sleep) || p.hardestTimes.contains(.bedtime) { out.append("Your phone follows you to bed. Leaf guards your wind-down.") }
            if p.struggles.contains(.breaks) { out.append("You forget to take breaks. Leaf never does.") }
            if p.goal == .calm || p.goal == .sleep { out.append("You want to \(p.goal!.title.lowercased()). That's Leaf's specialty.") }
        case .pebble:
            if p.struggles.contains(.scrolling) { out.append("Endless scrolling needs a firm hand. Pebble locks the door.") }
            if p.dailyScreenHours >= 6 { out.append("\(Int(p.dailyScreenHours)) hours a day is a lot. Pebble's strict mode helps you cut back.") }
            if p.motivation == .toughLove { out.append("You asked for tough love. Pebble delivers.") }
        case .blob:
            if p.motivation == .data { out.append("You love seeing progress. Blob turns every minute into a chart.") }
            if p.goal == .habits { out.append("Habits stick when you can see them. Blob tracks every streak.") }
            if p.role == .founder { out.append("You run on metrics. So does Blob.") }
        }
        if out.isEmpty { out.append("\(m.name)'s style matches how you answered: \(m.tagline.lowercased())") }
        if out.count < 2 { out.append("\(m.specialty).") }
        return Array(out.prefix(3))
    }

    /// Years of remaining life spent on the phone at the current pace (until age 80).
    static func yearsOnPhone(_ p: UserProfile) -> Double {
        let age = p.age?.midAge ?? 30
        let remainingYears = max(5, 80 - age)
        return p.dailyScreenHours / 24 * remainingYears
    }

    /// Years won back by cutting `hours` per day.
    static func yearsSaved(cuttingHours hours: Double, _ p: UserProfile) -> Double {
        let age = p.age?.midAge ?? 30
        let remainingYears = max(5, 80 - age)
        return hours / 24 * remainingYears
    }
}
