import SwiftUI

/// How a mascot moves while on screen.
enum MascotMotion {
    case still, breathe, float, bounce
}

/// Renders a crew member with its tinted circle, decoration and expression,
/// and brings it to life with breathing, blinking and floating.
struct MascotView: View {
    let mascot: Mascot
    var mood: MascotMood = .happy
    var size: CGFloat = 200
    var showCircle: Bool = true
    var showDecoration: Bool = true
    var motion: MascotMotion = .breathe
    var circleColor: Color?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Geometry of the artwork (see design/mascots/generate.py): 512pt canvas,
    // circle centred at (256, 236) with radius 200.
    private var circleDiameter: CGFloat { size * 400 / 512 }
    private var circleOffset: CGFloat { -size * 20 / 512 }

    var body: some View {
        if motion == .still || reduceMotion {
            artwork(at: 0)
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                artwork(at: context.date.timeIntervalSinceReferenceDate)
            }
        }
    }

    private func artwork(at t: TimeInterval) -> some View {
        let seed = Double(mascot.rawValue.count) * 0.7
        let breathe = sin((t + seed) * 2.1)
        let blinkCycle = (t + seed).truncatingRemainder(dividingBy: 4.3)
        let blinking = (mood == .idle) && motion != .still && blinkCycle < 0.13
        let shown: MascotMood = blinking ? .blink : mood

        var yOffset: CGFloat = 0
        var squashX: CGFloat = 1
        var squashY: CGFloat = 1
        switch motion {
        case .still:
            break
        case .breathe:
            squashX = 1 + 0.008 * breathe
            squashY = 1 - 0.012 * breathe
        case .float:
            yOffset = CGFloat(sin((t + seed) * 1.5)) * size * 0.022
            squashX = 1 + 0.006 * breathe
            squashY = 1 - 0.008 * breathe
        case .bounce:
            let phase = (t * 2.4).truncatingRemainder(dividingBy: 1)
            let hop = abs(sin(phase * .pi))
            yOffset = -CGFloat(hop) * size * 0.07
            let landing = max(0, 1 - phase * 6)
            squashX = 1 + 0.05 * landing
            squashY = 1 - 0.06 * landing
        }

        let decoPulse = motion == .still ? 1 : 1 + 0.06 * sin((t + seed) * 3.0)
        let decoLift = motion == .still ? 0 : CGFloat(sin((t + seed) * 1.2)) * size * 0.012

        return ZStack {
            if showCircle {
                Circle()
                    .fill(circleColor ?? mascot.tint)
                    .frame(width: circleDiameter, height: circleDiameter)
                    .offset(y: circleOffset)
            }
            if showDecoration && decorationVisible {
                Image(mascot.decorationAsset)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .scaleEffect(decoPulse, anchor: decorationAnchor)
                    .offset(y: decoLift)
                    .opacity(0.95)
            }
            Image(mascot.asset(shown))
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .scaleEffect(x: squashX, y: squashY, anchor: .bottom)
                .offset(y: yOffset)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(mascot.name), \(mascot.title)")
    }

    private var decorationVisible: Bool {
        if mascot == .leaf { return mood == .sleepy }
        return true
    }

    private var decorationAnchor: UnitPoint {
        // Decorations sit in the top-right corner of the artwork.
        UnitPoint(x: 0.8, y: 0.25)
    }
}

/// Round head-and-shoulders avatar for small places (lists, widgets, Dynamic Island).
struct MascotAvatar: View {
    let mascot: Mascot
    var size: CGFloat = 40
    var ring: Color? = nil

    var body: some View {
        Image(mascot.avatarAsset)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay {
                if let ring {
                    Circle().strokeBorder(ring, lineWidth: max(1.5, size * 0.05))
                }
            }
            .accessibilityLabel(mascot.name)
    }
}

/// A rounded speech bubble with a little tail pointing at the speaker.
struct SpeechBubble: View {
    let text: String
    var tailEdge: Edge = .bottom
    var tailOffset: CGFloat = 0
    var fill: Color = Theme.surface
    var font: Font = .rounded(.callout, weight: .semibold)

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(Theme.ink)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(fill)
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
            )
            .overlay(alignment: tailAlignment) {
                BubbleTail()
                    .fill(fill)
                    .frame(width: 18, height: 10)
                    .rotationEffect(tailRotation)
                    .offset(tailShift)
            }
    }

    private var tailAlignment: Alignment {
        switch tailEdge {
        case .bottom: return .bottom
        case .top: return .top
        case .leading: return .leading
        case .trailing: return .trailing
        }
    }

    private var tailRotation: Angle {
        switch tailEdge {
        case .bottom: return .zero
        case .top: return .degrees(180)
        case .leading: return .degrees(90)
        case .trailing: return .degrees(-90)
        }
    }

    private var tailShift: CGSize {
        switch tailEdge {
        case .bottom: return CGSize(width: tailOffset, height: 9)
        case .top: return CGSize(width: tailOffset, height: -9)
        case .leading: return CGSize(width: -13, height: tailOffset)
        case .trailing: return CGSize(width: 13, height: tailOffset)
        }
    }
}

private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.midX * 0.9, y: rect.minY + 2))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX * 1.1, y: rect.minY + 2))
        p.closeSubpath()
        return p
    }
}

/// A capsule chip with an SF Symbol, like the trait chips in the crew artwork.
struct TraitChip: View {
    let title: String
    let symbol: String
    var tint: Color = Theme.ink
    var background: Color = Theme.surfaceMuted

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
            Text(title)
                .font(.rounded(.subheadline, weight: .semibold))
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(background))
    }
}

/// Circular progress ring.
struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 10
    var tint: Color = Theme.ink
    var track: Color = Theme.surfaceMuted

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.0001, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
