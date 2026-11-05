import SwiftUI

// MARK: - Buttons

/// Big black capsule, the main call to action on every screen.
struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.ink
    var foreground: Color = Theme.inkInverse
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rounded(.headline, weight: .bold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(Capsule().fill(tint.opacity(isEnabled ? 1 : 0.25)))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .contentShape(Capsule())
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rounded(.headline, weight: .semibold))
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Capsule().fill(Theme.surfaceMuted))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .contentShape(Capsule())
    }
}

/// Text-only button used for "Skip", "Not now" and similar.
struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rounded(.subheadline, weight: .semibold))
            .foregroundStyle(Theme.inkSecondary)
            .padding(.vertical, 10)
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

/// Bouncy press feedback for cards and tiles.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Round icon button (close, settings, plus/minus).
struct CircleIconButton: View {
    let symbol: String
    var size: CGFloat = 40
    var tint: Color = Theme.ink
    var background: Color = Theme.surface
    var label: String = ""
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(Circle().fill(background))
                .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: background == Theme.surface ? 1 : 0))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(label.isEmpty ? symbol : label)
    }
}

// MARK: - Layout helpers

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.rounded(.title3, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            if let trailing, let action {
                Button(trailing, action: action)
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
        .padding(.horizontal, 4)
    }
}

/// Small rounded-square icon used in rows.
struct IconBadge: View {
    let symbol: String
    var tint: Color = Theme.ink
    var background: Color = Theme.surfaceMuted
    var size: CGFloat = 36

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).fill(background))
    }
}

/// A stat with a big number and a caption.
struct StatTile: View {
    let value: String
    let label: String
    var symbol: String? = nil
    var tint: Color = Theme.ink

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tint)
            }
            Text(value)
                .font(.rounded(.title2, weight: .bold))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.rounded(.caption, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16)
    }
}

/// Horizontal progress bar.
struct ProgressBar: View {
    var progress: Double
    var tint: Color = Theme.ink
    var track: Color = Theme.surfaceMuted
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(tint)
                    .frame(width: max(height, geo.size.width * min(1, max(0, progress))))
            }
        }
        .frame(height: height)
    }
}

// MARK: - Toast

struct ToastView: View {
    let text: String
    let mascot: Mascot

    var body: some View {
        HStack(spacing: 10) {
            MascotAvatar(mascot: mascot, size: 30)
            Text(text)
                .font(.rounded(.subheadline, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
        }
        .padding(.leading, 8)
        .padding(.trailing, 18)
        .padding(.vertical, 8)
        .background(Capsule().fill(Theme.surface).shadow(color: .black.opacity(0.12), radius: 16, y: 6))
        .overlay(Capsule().strokeBorder(Theme.hairline))
    }
}

// MARK: - Hold to confirm

/// A button that must be held down; used for the pledge and for quitting strict sessions.
struct HoldToConfirmButton: View {
    let title: String
    var holdingTitle: String = "Keep holding\u{2026}"
    var duration: Double = 1.6
    var tint: Color = Theme.ink
    var foreground: Color = Theme.inkInverse
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var isHolding = false
    @State private var done = false

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(tint.opacity(0.18))
            GeometryReader { geo in
                Capsule()
                    .fill(tint)
                    .frame(width: max(58, geo.size.width * progress))
            }
            Text(done ? "Done!" : (isHolding ? holdingTitle : title))
                .font(.rounded(.headline, weight: .bold))
                .foregroundStyle(progress > 0.5 ? foreground : Theme.ink)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 58)
        .clipShape(Capsule())
        .contentShape(Capsule())
        .onLongPressGesture(minimumDuration: duration, maximumDistance: 60, perform: {
            done = true
            Haptics.success()
            onComplete()
        }, onPressingChanged: { pressing in
            guard !done else { return }
            isHolding = pressing
            if pressing {
                Haptics.soft()
                withAnimation(.linear(duration: duration)) { progress = 1 }
            } else {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { progress = 0 }
            }
        })
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(title)
        .accessibilityAction { onComplete() }
    }
}

// MARK: - Confetti

/// Lightweight confetti burst drawn with Canvas.
struct ConfettiView: View {
    var colors: [Color] = [Color("OrbitAccent"), Color("SparkAccent"), Color("LeafAccent"), Color("BlobAccent"), Theme.flame, Color("SparkTint")]
    var count: Int = 90
    var duration: Double = 3.2

    @State private var start = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Piece {
        let x: Double, delay: Double, speed: Double, spin: Double, drift: Double, size: Double, colorIndex: Int, shape: Int
    }

    @State private var pieces: [Piece] = []

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSince(start)
                for p in pieces {
                    let local = t - p.delay
                    guard local > 0, local < duration else { continue }
                    let y = -20 + local * p.speed * size.height / 2.2 + 0.5 * 260 * local * local
                    guard y < size.height + 30 else { continue }
                    let x = p.x * size.width + sin(local * 3 + p.drift) * 24
                    let opacity = local > duration - 0.6 ? (duration - local) / 0.6 : 1
                    var c = ctx
                    c.opacity = opacity
                    c.translateBy(x: x, y: y)
                    c.rotate(by: .degrees(local * p.spin))
                    let rect = CGRect(x: -p.size / 2, y: -p.size / 4, width: p.size, height: p.shape == 0 ? p.size / 2 : p.size)
                    let path = p.shape == 2 ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 2)
                    c.fill(path, with: .color(colors[p.colorIndex % colors.count]))
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            start = Date()
            pieces = (0..<count).map { _ in
                Piece(
                    x: Double.random(in: 0...1), delay: Double.random(in: 0...0.5), speed: Double.random(in: 0.3...1.1),
                    spin: Double.random(in: -360...360), drift: Double.random(in: 0...6), size: Double.random(in: 7...13),
                    colorIndex: Int.random(in: 0..<100), shape: Int.random(in: 0...2)
                )
            }
        }
    }
}

// MARK: - Misc

extension View {
    /// Applies the user's appearance preference.
    @ViewBuilder
    func appearance(_ pref: AppearancePreference) -> some View {
        switch pref {
        case .system: self
        case .light: self.preferredColorScheme(.light)
        case .dark: self.preferredColorScheme(.dark)
        }
    }

    /// Standard page background.
    func pageBackground(_ color: Color = Theme.background) -> some View {
        self.background(color.ignoresSafeArea())
    }
}

/// Small wrapper for "x of y" weekday dots.
struct WeekdayDots: View {
    let selected: [Int]
    var tint: Color = Theme.ink

    private let order = [2, 3, 4, 5, 6, 7, 1]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(order, id: \.self) { day in
                let on = selected.contains(day)
                Text(String(Calendar.current.veryShortWeekdaySymbols[day - 1]))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(on ? Theme.inkInverse : Theme.inkTertiary)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(on ? tint : Theme.surfaceMuted))
            }
        }
    }
}
