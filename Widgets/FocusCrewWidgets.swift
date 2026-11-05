import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct FocusCrewWidgetBundle: WidgetBundle {
    var body: some Widget {
        CrewStatusWidget()
        FocusLiveActivityWidget()
        if #available(iOS 18.0, *) {
            StartFocusControl()
        }
    }
}

// MARK: - Status widget (Home Screen + Lock Screen)

struct CrewProvider: TimelineProvider {
    func placeholder(in context: Context) -> CrewEntry {
        CrewEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CrewEntry) -> Void) {
        let snapshot = context.isPreview ? .placeholder : (SharedFiles.snapshot.load() ?? .placeholder)
        completion(CrewEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CrewEntry>) -> Void) {
        let now = Date()
        var snapshot = SharedFiles.snapshot.load() ?? .placeholder
        // The session file is the freshest source of truth for the running timer.
        snapshot.active = SharedFiles.activeSession.load()
        var entries = [CrewEntry(date: now, snapshot: snapshot)]
        if let active = snapshot.active, !active.isPaused, active.endsAt > now {
            // Flip to the "done" state right when the session ends.
            var after = snapshot
            after.active = nil
            entries.append(CrewEntry(date: active.endsAt.addingTimeInterval(1), snapshot: after))
        }
        // Refresh after midnight so "today" resets, or in 30 minutes, whichever is sooner.
        let midnight = Calendar.current.startOfDay(for: now.addingTimeInterval(86_400))
        let refresh = min(midnight.addingTimeInterval(60), now.addingTimeInterval(30 * 60))
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }
}

struct CrewStatusWidget: Widget {
    let kind = "FocusCrewStatus"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CrewProvider()) { entry in
            CrewStatusEntryView(entry: entry)
        }
        .configurationDisplayName("Focus Crew")
        .description("Your companion, today's focus time and the live session timer.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
        .contentMarginsDisabled()
    }
}

struct CrewStatusEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CrewEntry

    var body: some View {
        CrewWidgetView(entry: entry, family: family)
            .padding(padding)
            .containerBackground(for: .widget) {
                CrewWidgetBackground(snapshot: entry.snapshot, family: family)
            }
    }

    private var padding: CGFloat {
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: return 0
        default: return 16
        }
    }
}

// MARK: - Live Activity + Dynamic Island

struct FocusLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            FocusLockScreenView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Color(red: 0.09, green: 0.09, blue: 0.11).opacity(0.92))
                .activitySystemActionForegroundColor(.white)
                .widgetURL(URL(string: "focuscrew://session"))
        } dynamicIsland: { context in
            let m = context.attributes.mascot
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    IslandAvatar(mascot: m, mood: context.state.mascotMood, size: 52)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    LiveCountdown(state: context.state, font: .rounded(size: 30, weight: .heavy))
                        .foregroundStyle(m.vivid)
                        .frame(maxWidth: 120, alignment: .trailing)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.finished ? "Session complete!" : (context.state.isRest ? "On a break" : (context.state.isPaused ? "Paused" : "Focusing with \(m.name)")))
                        .font(.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    IslandExpandedBottom(attributes: context.attributes, state: context.state)
                        .padding(.horizontal, 4)
                }
            } compactLeading: {
                IslandAvatar(mascot: m, mood: context.state.mascotMood, size: 24)
            } compactTrailing: {
                LiveCountdown(state: context.state, font: .rounded(size: 15, weight: .bold))
                    .foregroundStyle(m.vivid)
                    .frame(maxWidth: 52)
            } minimal: {
                IslandAvatar(mascot: m, mood: context.state.mascotMood, size: 22)
            }
            .keylineTint(m.vivid)
            .widgetURL(URL(string: "focuscrew://session"))
        }
    }
}

// MARK: - Control Center (iOS 18+)

@available(iOS 18.0, *)
struct StartFocusControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.focuscrew.control.start") {
            ControlWidgetButton(action: StartFocusIntent()) {
                Label("Start Focus", systemImage: "scope")
            }
        }
        .displayName("Start Focus")
        .description("Start a focus session with your Focus Crew companion.")
    }
}
