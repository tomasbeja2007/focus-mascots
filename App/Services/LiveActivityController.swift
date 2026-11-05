import ActivityKit
import Foundation

/// Starts, updates and ends the Lock Screen / Dynamic Island Live Activity.
enum LiveActivityController {
    static var isAvailable: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    static func state(for s: ActiveSession, finished: Bool = false) -> FocusActivityAttributes.ContentState {
        let mood: MascotMood
        if finished {
            mood = .excited
        } else if s.kind == .rest {
            mood = .sleepy
        } else if s.isPaused {
            mood = .idle
        } else {
            mood = .focused
        }
        return FocusActivityAttributes.ContentState(
            startedAt: s.startedAt,
            endsAt: s.endsAt,
            pausedRemaining: s.isPaused ? s.remaining() : nil,
            isRest: s.kind == .rest,
            mood: mood.rawValue,
            finished: finished
        )
    }

    static func start(_ session: ActiveSession, enabled: Bool) {
        guard enabled, isAvailable else { return }
        let attributes = FocusActivityAttributes(
            mascot: session.mascot,
            intention: session.intention,
            plannedSeconds: session.plannedSeconds,
            strict: session.strict
        )
        Task {
            await endAll(immediately: true)
            do {
                _ = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: state(for: session), staleDate: session.endsAt.addingTimeInterval(5 * 60)),
                    pushType: nil
                )
            } catch {
                // Live Activities can be switched off per app; the session still works without one.
            }
        }
    }

    static func update(_ session: ActiveSession) {
        Task {
            let content = ActivityContent(
                state: state(for: session),
                staleDate: session.isPaused ? nil : session.endsAt.addingTimeInterval(5 * 60)
            )
            for activity in Activity<FocusActivityAttributes>.activities {
                await activity.update(content)
            }
        }
    }

    /// Shows a short "done" state, then removes the activity.
    static func finish(_ session: ActiveSession, completed: Bool) {
        Task {
            var s = session
            s.pausedAt = nil
            let content = ActivityContent(state: state(for: s, finished: completed), staleDate: nil)
            for activity in Activity<FocusActivityAttributes>.activities {
                await activity.end(content, dismissalPolicy: completed ? .after(Date().addingTimeInterval(15 * 60)) : .immediate)
            }
        }
    }

    static func endAll(immediately: Bool) async {
        for activity in Activity<FocusActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: immediately ? .immediate : .default)
        }
    }
}
