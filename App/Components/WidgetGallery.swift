import SwiftUI
import WidgetKit

/// In-app preview of the widgets and Live Activity (Settings › Widgets, and CI screenshots).
struct WidgetGallery: View {
    let snapshot: CrewSnapshot
    var showLive = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                widget(.systemSmall, width: 158, height: 158)
                widget(.systemSmall, width: 158, height: 158, active: true)
            }
            widget(.systemMedium, width: 330, height: 158)
            HStack(spacing: 12) {
                lockWidget(.accessoryCircular, width: 72, height: 72)
                lockWidget(.accessoryRectangular, width: 170, height: 72)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 0.25, green: 0.3, blue: 0.45), Color(red: 0.42, green: 0.36, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .environment(\.colorScheme, .dark)
        }
    }

    private func entry(active: Bool) -> CrewEntry {
        var s = snapshot
        if active && s.active == nil {
            s.active = ActiveSession(kind: .focus, minutes: 25, mascot: s.mascot, intention: "Write the report", blocking: true, blockedItems: 9, start: Date().addingTimeInterval(-7 * 60))
        }
        if !active { s.active = nil }
        return CrewEntry(date: Date(), snapshot: s)
    }

    private func widget(_ family: WidgetFamily, width: CGFloat, height: CGFloat, active: Bool = false) -> some View {
        let e = entry(active: active)
        return CrewWidgetView(entry: e, family: family)
            .padding(16)
            .frame(width: width, height: height)
            .background(CrewWidgetBackground(snapshot: e.snapshot, family: family))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }

    private func lockWidget(_ family: WidgetFamily, width: CGFloat, height: CGFloat) -> some View {
        CrewWidgetView(entry: entry(active: true), family: family)
            .foregroundStyle(.white)
            .frame(width: width, height: height)
    }
}

/// In-app preview of the Live Activity and Dynamic Island.
struct LiveActivityGallery: View {
    let mascot: Mascot

    private var attributes: FocusActivityAttributes {
        FocusActivityAttributes(mascot: mascot, intention: "Write the report", plannedSeconds: 25 * 60, strict: false)
    }

    private var state: FocusActivityAttributes.ContentState {
        FocusActivityAttributes.ContentState(
            startedAt: Date().addingTimeInterval(-7 * 60),
            endsAt: Date().addingTimeInterval(18 * 60 + 42),
            pausedRemaining: nil,
            isRest: false,
            mood: MascotMood.focused.rawValue
        )
    }

    var body: some View {
        VStack(spacing: 18) {
            // Compact Dynamic Island
            HStack(spacing: 0) {
                IslandAvatar(mascot: mascot, mood: .focused, size: 24)
                Spacer()
                LiveCountdown(state: state, font: .rounded(size: 15, weight: .bold))
                    .foregroundStyle(mascot.vivid)
                    .frame(maxWidth: 52)
            }
            .padding(.horizontal, 10)
            .frame(width: 250, height: 37)
            .background(Capsule().fill(.black))

            // Expanded Dynamic Island
            VStack(spacing: 10) {
                HStack {
                    IslandAvatar(mascot: mascot, mood: .focused, size: 52)
                    Spacer()
                    Text("Focusing with \(mascot.name)")
                        .font(.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    LiveCountdown(state: state, font: .rounded(size: 26, weight: .heavy))
                        .foregroundStyle(mascot.vivid)
                        .frame(maxWidth: 90, alignment: .trailing)
                }
                IslandExpandedBottom(attributes: attributes, state: state)
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 44, style: .continuous).fill(.black))

            // Lock Screen
            FocusLockScreenView(attributes: attributes, state: state)
                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color(red: 0.09, green: 0.09, blue: 0.11).opacity(0.92)))
        }
    }
}
