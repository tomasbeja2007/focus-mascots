import SwiftUI

/// Design tokens. Colours live in Shared/Theme.xcassets (light + dark).
enum Theme {
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let surfaceMuted = Color("SurfaceMuted")
    static let hairline = Color("Hairline")
    static let ink = Color("Ink")
    static let inkSecondary = Color("InkSecondary")
    static let inkTertiary = Color("InkTertiary")
    static let inkInverse = Color("InkInverse")
    static let success = Color("Success")
    static let warning = Color("Warning")
    static let danger = Color("Danger")
    static let flame = Color("Flame")

    static let cornerLarge: CGFloat = 28
    static let corner: CGFloat = 20
    static let cornerSmall: CGFloat = 14
    static let pagePadding: CGFloat = 20
}

extension Mascot {
    /// Soft circle behind the mascot.
    var tint: Color { Color("\(name)Tint") }
    /// Strong colour for progress rings, highlights and buttons.
    var accent: Color { Color("\(name)Accent") }
    /// Very light page wash.
    var wash: Color { Color("\(name)Wash") }

    /// Bright accent that reads well on dark surfaces (Live Activity, Mac notch).
    var vivid: Color {
        switch self {
        case .orbit: return Color(red: 0.49, green: 0.65, blue: 0.95)
        case .spark: return Color(red: 1.0, green: 0.67, blue: 0.37)
        case .leaf: return Color(red: 0.56, green: 0.78, blue: 0.50)
        case .pebble: return Color(red: 0.70, green: 0.75, blue: 0.84)
        case .blob: return Color(red: 0.71, green: 0.65, blue: 0.96)
        }
    }
}

extension Font {
    /// SF Pro Rounded at a Dynamic Type style.
    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }

    /// SF Pro Rounded at a fixed size (scaled with Dynamic Type where used with `relativeTo`).
    static func rounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension View {
    /// The standard card look: surface, large continuous corners, hairline and soft shadow.
    func cardStyle(padding: CGFloat = 18, radius: CGFloat = Theme.corner) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}
