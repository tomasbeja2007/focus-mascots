import Foundation

/// The five members of the Focus Crew.
enum Mascot: String, Codable, CaseIterable, Identifiable, Hashable {
    case orbit, spark, leaf, pebble, blob

    var id: String { rawValue }

    var name: String {
        switch self {
        case .orbit: return "Orbit"
        case .spark: return "Spark"
        case .leaf: return "Leaf"
        case .pebble: return "Pebble"
        case .blob: return "Blob"
        }
    }

    var title: String {
        switch self {
        case .orbit: return "The Focus Companion"
        case .spark: return "The Motivation Boost"
        case .leaf: return "The Rest Guardian"
        case .pebble: return "The Discipline Coach"
        case .blob: return "The Progress Tracker"
        }
    }

    /// One-word superpower shown in the trait chip.
    var trait: String {
        switch self {
        case .orbit: return "Focus"
        case .spark: return "Energy"
        case .leaf: return "Recovery"
        case .pebble: return "Habits"
        case .blob: return "Progress"
        }
    }

    /// SF Symbol for the trait chip.
    var traitSymbol: String {
        switch self {
        case .orbit: return "scope"
        case .spark: return "bolt.fill"
        case .leaf: return "moon.fill"
        case .pebble: return "dumbbell.fill"
        case .blob: return "chart.line.uptrend.xyaxis"
        }
    }

    var tagline: String {
        switch self {
        case .orbit: return "Calm, steady, always in the zone."
        case .spark: return "Small wins, big momentum."
        case .leaf: return "Slow down to speed up."
        case .pebble: return "No excuses. Just reps."
        case .blob: return "Every minute counts."
        }
    }

    var bio: String {
        switch self {
        case .orbit:
            return "Orbit floats you away from the noise. A quiet co-pilot for deep work, Orbit keeps you on course one session at a time."
        case .spark:
            return "Spark turns \u{201C}I'll do it later\u{201D} into \u{201C}I'm doing it now.\u{201D} Short, punchy sessions that build momentum fast."
        case .leaf:
            return "Leaf reminds you that rest is part of the work. Gentle sessions, real breaks and a phone-free wind-down every night."
        case .pebble:
            return "Pebble is small but unshakeable. Strict mode on, apps locked, and a coach that won't let you quit early."
        case .blob:
            return "Blob loves numbers. It tracks every focused minute, celebrates every streak and shows you how far you've come."
        }
    }

    var specialty: String {
        switch self {
        case .orbit: return "Classic 25-minute deep-work sessions"
        case .spark: return "Quick 15-minute sprints that beat procrastination"
        case .leaf: return "Balanced sessions, real breaks and a bedtime wind-down"
        case .pebble: return "Strict sessions that can't be skipped"
        case .blob: return "Streaks, stats and weekly progress"
        }
    }

    /// Session length the mascot suggests by default.
    var defaultMinutes: Int {
        switch self {
        case .orbit: return 25
        case .spark: return 15
        case .leaf: return 30
        case .pebble: return 45
        case .blob: return 25
        }
    }

    var prefersStrictMode: Bool { self == .pebble }

    func asset(_ mood: MascotMood) -> String { "\(rawValue)_\(mood.rawValue)" }
    var decorationAsset: String { "\(rawValue)_deco" }
    var avatarAsset: String { "\(rawValue)_avatar" }
    /// Round head crop with a given expression, for small places.
    func avatarAsset(_ mood: MascotMood) -> String {
        mood == .happy ? avatarAsset : "\(rawValue)_avatar_\(mood.rawValue)"
    }

    /// The expression the mascot wears when resting on screen.
    var restingMood: MascotMood {
        switch self {
        case .leaf: return .sleepy
        case .pebble: return .focused
        default: return .happy
        }
    }
}

/// Expressions available for every mascot (see design/mascots).
enum MascotMood: String, Codable, CaseIterable {
    case idle, blink, happy, focused, sleepy, sad, excited
}

// MARK: - Voice lines

extension Mascot {
    var greetings: [String] {
        switch self {
        case .orbit:
            return ["Systems ready. Shall we focus?", "Clear skies for deep work today.", "Let's drift away from the noise.", "One small step for focus."]
        case .spark:
            return ["Let's go! What are we crushing today?", "I've got energy for both of us!", "Tiny start, huge momentum.", "Five minutes in and you'll be flying."]
        case .leaf:
            return ["Breathe in. Let's take this slowly.", "No rush. One calm session at a time.", "Rested minds focus best.", "Hi\u{2026} let's do this gently."]
        case .pebble:
            return ["Phone down. Focus up.", "Discipline is a habit. Let's train.", "No excuses today.", "Rocks don't scroll. Neither do we."]
        case .blob:
            return ["Ready to add some minutes to the chart?", "Your graph wants to go up today!", "Every session counts. I count them.", "Let's make today's bar the tallest."]
        }
    }

    var encouragements: [String] {
        switch self {
        case .orbit:
            return ["Steady orbit. Keep going.", "You're in the zone. I can tell.", "Distractions are light-years away.", "Smooth flying so far.", "Stay on course. You're doing great."]
        case .spark:
            return ["You're on fire! Literally, I'm a flame.", "Don't stop now. Momentum is everything!", "Look at you go!", "Keep that energy up!", "This is the good part. Push!"]
        case .leaf:
            return ["Nice and steady. You're doing great.", "Remember to unclench your jaw.", "Slow and steady wins.", "Just this one task. Nothing else.", "Soft shoulders, deep breath."]
        case .pebble:
            return ["Hold the line.", "Stay solid. You've got this.", "Discomfort means it's working.", "Not one tap. I'm watching.", "Every minute is a rep."]
        case .blob:
            return ["Data says: you're doing great.", "Progress bar loading\u{2026} keep going!", "Each minute is a new data point.", "This will look great on your chart.", "Trend line: up and to the right."]
        }
    }

    var completions: [String] {
        switch self {
        case .orbit: return ["Mission complete! Beautiful focus.", "Touchdown. That was stellar.", "Perfect landing. Proud of you."]
        case .spark: return ["Boom! Session crushed!", "That's what I'm talking about!", "You just turned \u{201C}later\u{201D} into \u{201C}done\u{201D}!"]
        case .leaf: return ["Lovely work. Now, a real break.", "Peaceful and productive. My favourite.", "Time to stretch, sip water and rest your eyes."]
        case .pebble: return ["Solid work. Respect.", "Another rep in the bank.", "Unshakeable. Same time tomorrow."]
        case .blob: return ["New data point unlocked!", "Look at that bar grow!", "Your weekly trend just went up."]
        }
    }

    var gaveUpLines: [String] {
        switch self {
        case .orbit: return ["Re-entry happens. Every launch teaches us something.", "We'll relaunch soon. The stars aren't going anywhere."]
        case .spark: return ["No worries, we'll reignite in a bit!", "Even sparks flicker. Let's try again soon."]
        case .leaf: return ["It's okay to stop. Rest, then return.", "Be kind to yourself. We'll try again."]
        case .pebble: return ["We stop today, we come back stronger.", "Setbacks are part of training. Reset."]
        case .blob: return ["Partial minutes still count on my chart.", "Every bit of focus is logged. Try again soon."]
        }
    }

    var breakLines: [String] {
        switch self {
        case .orbit: return ["Floating in zero-g for a minute.", "Look at something far away. Like the moon."]
        case .spark: return ["Recharge time! Shake it out.", "Quick break, then we go again!"]
        case .leaf: return ["Stretch, sip some water, breathe.", "This is my favourite part."]
        case .pebble: return ["Short rest. Then back to work.", "Recover. Don't scroll."]
        case .blob: return ["Breaks are part of the data too.", "Resting improves your next session."]
        }
    }

    /// Title shown on top of blocked apps.
    var shieldTitle: String {
        switch self {
        case .orbit: return "Orbit is keeping you on course"
        case .spark: return "Spark says: not now, superstar!"
        case .leaf: return "Leaf is guarding your calm"
        case .pebble: return "Pebble says: hold the line"
        case .blob: return "Blob is protecting your streak"
        }
    }

    func line(from lines: [String], seed: Int) -> String {
        guard !lines.isEmpty else { return "" }
        return lines[abs(seed) % lines.count]
    }
}
