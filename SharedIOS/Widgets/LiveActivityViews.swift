import AppIntents
import SwiftUI
import WidgetKit

/// Lock Screen / banner presentation of the focus Live Activity.
struct FocusLockScreenView: View {
    let attributes: FocusActivityAttributes
    let state: FocusActivityAttributes.ContentState

    private var m: Mascot { attributes.mascot }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(m.tint)
                    Image(m.asset(state.mascotMood))
                        .resizable()
                        .scaledToFit()
                        .padding(-6)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 2) {
                    Text(headline)
                        .font(.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(m.vivid)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(subline)
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .layoutPriority(1)
                Spacer(minLength: 4)
                LiveCountdown(state: state, font: .rounded(size: 32, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 104, alignment: .trailing)
            }
            if !state.finished {
                HStack(spacing: 10) {
                    LiveProgress(state: state, tint: m.vivid)
                    if !attributes.strict && !state.isRest {
                        if state.isPaused {
                            Button(intent: ResumeFocusIntent()) {
                                Image(systemName: "play.fill")
                            }
                            .buttonStyle(LiveButtonStyle(tint: m.vivid))
                        } else {
                            Button(intent: PauseFocusIntent()) {
                                Image(systemName: "pause.fill")
                            }
                            .buttonStyle(LiveButtonStyle(tint: .white.opacity(0.18)))
                        }
                    }
                    if !attributes.strict || state.isRest {
                        Button(intent: EndFocusIntent()) {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(LiveButtonStyle(tint: .white.opacity(0.18)))
                    }
                }
            }
        }
        .padding(16)
    }

    private var headline: String {
        if state.finished { return state.isRest ? "Break's over" : "Session complete!" }
        if state.isRest { return "On a break" }
        if state.isPaused { return "Paused" }
        return "Focusing with \(m.name)"
    }

    private var subline: String {
        if state.finished { return state.isRest ? "Ready for another round?" : m.line(from: m.completions, seed: attributes.plannedSeconds) }
        if !attributes.intention.isEmpty { return attributes.intention }
        return state.isRest ? "Stretch and breathe" : m.tagline
    }
}

struct LiveButtonStyle: ButtonStyle {
    var tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 38, height: 38)
            .background(Circle().fill(tint))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Countdown that ticks on its own, or a frozen value while paused.
struct LiveCountdown: View {
    let state: FocusActivityAttributes.ContentState
    var font: Font

    var body: some View {
        Group {
            if state.finished {
                Image(systemName: "checkmark.circle.fill")
            } else if let paused = state.pausedRemaining {
                Text(Format.clock(paused))
            } else {
                Text(timerInterval: state.startedAt...max(state.startedAt, state.endsAt), countsDown: true)
            }
        }
        .font(font)
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}

struct LiveProgress: View {
    let state: FocusActivityAttributes.ContentState
    var tint: Color

    var body: some View {
        if let paused = state.pausedRemaining {
            let total = max(1, state.endsAt.timeIntervalSince(state.startedAt))
            ProgressView(value: max(0, min(1, 1 - paused / total)))
                .tint(tint)
        } else {
            ProgressView(timerInterval: state.startedAt...max(state.startedAt, state.endsAt), countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(tint)
        }
    }
}

/// Pieces of the Dynamic Island, used by the widget extension and the in-app preview.
struct IslandAvatar: View {
    let mascot: Mascot
    var mood: MascotMood = .focused
    var size: CGFloat = 26

    var body: some View {
        Image(mascot.avatarAsset(mood))
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}

struct IslandExpandedBottom: View {
    let attributes: FocusActivityAttributes
    let state: FocusActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 10) {
            if !attributes.intention.isEmpty {
                Text(attributes.intention)
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 10) {
                LiveProgress(state: state, tint: attributes.mascot.vivid)
                if !state.finished {
                    if !attributes.strict && !state.isRest {
                        if state.isPaused {
                            Button(intent: ResumeFocusIntent()) { Image(systemName: "play.fill") }
                                .buttonStyle(LiveButtonStyle(tint: attributes.mascot.vivid))
                        } else {
                            Button(intent: PauseFocusIntent()) { Image(systemName: "pause.fill") }
                                .buttonStyle(LiveButtonStyle(tint: .white.opacity(0.18)))
                        }
                    }
                    if !attributes.strict || state.isRest {
                        Button(intent: EndFocusIntent()) { Image(systemName: "xmark") }
                            .buttonStyle(LiveButtonStyle(tint: .white.opacity(0.18)))
                    }
                }
            }
        }
    }
}
