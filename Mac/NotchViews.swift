import SwiftUI

/// The black "ears" around the notch (or a floating pill) with the mascot and timer.
struct NotchRootView: View {
    let layout: NotchLayout
    /// Overrides the shared expanded state (used by the debug preview).
    var forceExpanded: Bool?
    @State private var model = MacModel.shared
    @State private var hovering = false

    var body: some View {
        let expanded = forceExpanded ?? model.expanded
        VStack(spacing: 0) {
            collapsedRow
                .frame(height: layout.hasNotch ? layout.notchHeight : 36)
            if expanded {
                expandedContent
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(shape.fill(Color.black))
        .clipShape(shape)
        .overlay {
            if !layout.hasNotch {
                shape.stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
        }
        .contentShape(shape)
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                model.expanded.toggle()
            }
            model.refreshPanel()
        }
        .onHover { hovering = $0 }
        .scaleEffect(hovering && !expanded ? 1.02 : 1, anchor: .top)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hovering)
        .preferredColorScheme(.dark)
    }

    private var shape: some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius: layout.hasNotch ? 0 : 18,
            bottomLeadingRadius: 18,
            bottomTrailingRadius: 18,
            topTrailingRadius: layout.hasNotch ? 0 : 18,
            style: .continuous
        )
    }

    // MARK: Collapsed

    @ViewBuilder
    private var collapsedRow: some View {
        if layout.hasNotch {
            HStack(spacing: 0) {
                leftEar
                    .frame(width: layout.earWidth, alignment: .leading)
                Spacer(minLength: layout.notchWidth)
                rightEar
                    .frame(width: layout.earWidth, alignment: .trailing)
            }
            .padding(.horizontal, 10)
        } else {
            HStack(spacing: 8) {
                leftEar
                Spacer(minLength: 4)
                rightEar
            }
            .padding(.horizontal, 8)
        }
    }

    private var leftEar: some View {
        HStack(spacing: 6) {
            let mood: MascotMood = model.celebrating != nil ? .excited : (model.current?.isPaused == true ? .idle : .focused)
            Image(model.mascot.avatarAsset(mood))
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
                .padding(2.5)
                .overlay {
                    if let s = model.current, model.celebrating == nil {
                        ProgressRing(progress: s.progress(at: model.now), lineWidth: 2, tint: model.mascot.vivid, track: .white.opacity(0.15))
                    }
                }
            if !layout.hasNotch, let s = model.current, !s.intention.isEmpty {
                Text(s.intention)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
                    .frame(maxWidth: 96, alignment: .leading)
            }
        }
    }

    private var avatarSize: CGFloat { layout.hasNotch ? max(16, min(22, layout.notchHeight - 12)) : 22 }

    @ViewBuilder
    private var rightEar: some View {
        if model.celebrating != nil {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(model.mascot.vivid)
        } else if let s = model.current {
            HStack(spacing: 4) {
                if s.isPaused {
                    Image(systemName: "pause.fill").font(.system(size: 9, weight: .heavy))
                }
                Text(Format.clock(s.remaining(at: model.now)))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(s.isPaused ? Color.white.opacity(0.6) : model.mascot.vivid)
        }
    }

    // MARK: Expanded

    private var expandedContent: some View {
        HStack(spacing: 14) {
            Image(model.mascot.asset(model.celebrating != nil ? .excited : .focused))
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 84, height: 84)
                .background(Circle().fill(model.mascot.tint.opacity(0.9)).padding(6))
            VStack(alignment: .leading, spacing: 6) {
                if model.celebrating != nil {
                    Text("Session complete!")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text(model.mascot.line(from: model.mascot.completions, seed: 1))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                } else if let s = model.current {
                    Text(s.intention.isEmpty ? "Focusing with \(s.mascot.name)" : s.intention)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(model.isLocal ? "On this Mac · ends \(s.endsAt.formatted(date: .omitted, time: .shortened))" : "On your iPhone · ends \(s.endsAt.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.15))
                            Capsule().fill(s.mascot.vivid).frame(width: max(6, geo.size.width * s.progress(at: model.now)))
                        }
                    }
                    .frame(height: 6)
                    .padding(.vertical, 2)
                    if model.isLocal {
                        HStack(spacing: 8) {
                            pill(s.isPaused ? "Resume" : "Pause", symbol: s.isPaused ? "play.fill" : "pause.fill") { model.togglePause() }
                            pill("End", symbol: "stop.fill") { model.endLocal() }
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
        .padding(.top, layout.hasNotch ? 4 : 0)
    }

    private func pill(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.16)))
        }
        .buttonStyle(.plain)
    }
}

/// Debug preview of the notch indicator on a fake MacBook menu bar, so the notch
/// layout can be checked on Macs (and CI machines) without a notch.
struct NotchPreviewWindowContent: View {
    private let layout = NotchLayout(hasNotch: true, notchWidth: 186, notchHeight: 32)

    var body: some View {
        VStack(spacing: 26) {
            preview(expanded: false)
            preview(expanded: true)
        }
        .padding(24)
        .background(
            LinearGradient(colors: [Color(red: 0.36, green: 0.45, blue: 0.68), Color(red: 0.62, green: 0.5, blue: 0.72)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    private func preview(expanded: Bool) -> some View {
        let size = expanded ? layout.expandedSize : layout.collapsedSize
        return ZStack(alignment: .top) {
            Rectangle().fill(.white.opacity(0.25)).frame(height: layout.notchHeight)
            UnevenRoundedRectangle(bottomLeadingRadius: 10, bottomTrailingRadius: 10, style: .continuous)
                .fill(.black)
                .frame(width: layout.notchWidth, height: layout.notchHeight)
            NotchRootView(layout: layout, forceExpanded: expanded)
                .frame(width: size.width, height: size.height)
        }
        .frame(width: 620, height: layout.expandedSize.height, alignment: .top)
    }
}
