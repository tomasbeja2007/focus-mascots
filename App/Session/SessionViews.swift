import SwiftUI

/// Full-screen container: the running timer, then the celebration.
struct SessionContainerView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            if let summary = model.completion {
                CompletionView(summary: summary)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else if let session = model.active {
                ActiveSessionView(session: session)
                    .transition(.opacity)
            } else {
                Color.clear.onAppear { model.showSession = false }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: model.completion?.id)
    }
}

/// The running session: mascot inside a progress ring, countdown and controls.
struct ActiveSessionView: View {
    @Environment(AppModel.self) private var model
    let session: ActiveSession

    @State private var showEndConfirm = false
    @State private var lineSeed = Int.random(in: 0..<50)

    private var mascot: Mascot { session.mascot }
    private var isRest: Bool { session.kind == .rest }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let remaining = session.remaining(at: now)
            let progress = session.progress(at: now)
            ZStack {
                background
                VStack(spacing: 0) {
                    topBar
                    Spacer(minLength: 8)
                    SpeechBubble(text: bubbleText(now: now), tailEdge: .bottom)
                        .padding(.horizontal, 36)
                        .id(bubbleText(now: now))
                        .transition(.scale.combined(with: .opacity))
                    ZStack {
                        Circle()
                            .fill(Theme.surface.opacity(0.55))
                            .frame(width: 292, height: 292)
                        ProgressRing(progress: progress, lineWidth: 14, tint: mascot.accent, track: mascot.tint)
                            .frame(width: 300, height: 300)
                            .animation(.linear(duration: 1), value: progress)
                        MascotView(
                            mascot: mascot,
                            mood: mood,
                            size: 250,
                            showCircle: false,
                            showDecoration: !session.isPaused,
                            motion: session.isPaused ? .breathe : .float
                        )
                        .offset(y: 10)
                    }
                    .padding(.top, 14)

                    Text(Format.clock(remaining))
                        .font(.rounded(size: 76, weight: .heavy))
                        .monospacedDigit()
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.default, value: Int(remaining))
                        .padding(.top, 18)
                    statusChips
                        .padding(.top, 6)
                    Spacer(minLength: 12)
                    controls
                        .padding(.horizontal, Theme.pagePadding)
                        .padding(.bottom, 12)
                }
            }
        }
        .sheet(isPresented: $showEndConfirm) {
            EndSessionSheet(session: session)
                .environment(model)
                .presentationDetents([.height(session.strict ? 470 : 420)])
                .presentationCornerRadius(32)
        }
        .statusBarHidden(false)
    }

    private var mood: MascotMood {
        if isRest { return .sleepy }
        if session.isPaused { return .idle }
        return .focused
    }

    private var background: some View {
        LinearGradient(
            colors: [mascot.tint.opacity(session.isPaused ? 0.35 : 0.7), mascot.wash, Theme.background],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: session.isPaused)
    }

    private var topBar: some View {
        HStack {
            CircleIconButton(symbol: "chevron.down", size: 40, label: "Minimise") { model.showSession = false }
            Spacer()
            VStack(spacing: 2) {
                Text(isRest ? "BREAK" : (session.isPaused ? "PAUSED" : "FOCUSING WITH \(mascot.name.uppercased())"))
                    .font(.rounded(.caption, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(mascot.accent)
                Text(session.intention.isEmpty ? (isRest ? "Rest your eyes" : mascot.tagline) : session.intention)
                    .font(.rounded(.headline, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
            }
            Spacer()
            SoundButton()
        }
        .padding(.horizontal, Theme.pagePadding)
        .padding(.top, 8)
    }

    private var statusChips: some View {
        HStack(spacing: 8) {
            if session.blocking && !session.isPaused {
                TraitChip(title: "\(session.blockedItems) blocked", symbol: "lock.fill", tint: mascot.accent, background: Theme.surface)
            } else if session.blocking && session.isPaused {
                TraitChip(title: "Apps unlocked", symbol: "lock.open.fill", tint: Theme.warning, background: Theme.surface)
            }
            if session.strict {
                TraitChip(title: "Strict", symbol: "hand.raised.fill", tint: mascot.accent, background: Theme.surface)
            }
            if !session.isPaused {
                TraitChip(title: "Ends \(session.endsAt.formatted(date: .omitted, time: .shortened))", symbol: "clock.fill", tint: mascot.accent, background: Theme.surface)
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        if isRest {
            HStack(spacing: 12) {
                Button("Skip break") { model.endEarly() }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Focus again") {
                    let minutes = model.settings.defaultSessionMinutes
                    model.endEarly()
                    model.startFocus(minutes: minutes, intention: "", strict: model.settings.strictByDefault, block: model.settings.blockDuringFocus)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        } else if session.isPaused {
            HStack(spacing: 12) {
                Button("End") { showEndConfirm = true }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(width: 110)
                Button {
                    model.resume()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle(tint: mascot.accent, foreground: .white))
            }
        } else {
            HStack(spacing: 12) {
                if !session.strict && model.settings.allowPauses {
                    Button {
                        model.pause()
                    } label: {
                        Label("Pause", systemImage: "pause.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                Button {
                    showEndConfirm = true
                } label: {
                    Label(session.strict ? "Give up" : "End session", systemImage: "stop.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private func bubbleText(now: Date) -> String {
        if isRest { return mascot.line(from: mascot.breakLines, seed: lineSeed) }
        if session.isPaused { return "Take a breath. I'll wait right here." }
        // A new line every three minutes.
        let bucket = Int(session.elapsed(at: now) / 180)
        if session.remaining(at: now) < 60 { return "Final minute! Finish strong." }
        if bucket == 0 { return mascot.line(from: mascot.greetings, seed: lineSeed) }
        return mascot.line(from: mascot.encouragements, seed: lineSeed + bucket)
    }
}

/// Toggles the ambient focus sound from the session screen.
struct SoundButton: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Menu {
            Picker("Focus sound", selection: Binding(
                get: { model.settings.ambientSound },
                set: { value in
                    model.updateSettings { $0.ambientSound = value }
                    if model.active?.kind == .focus {
                        model.sounds.playAmbient(value, volume: model.settings.ambientVolume)
                        if model.active?.isPaused == true { model.sounds.pauseAmbient() }
                    }
                }
            )) {
                ForEach(AmbientSound.allCases) { s in
                    Label(s.title, systemImage: s.symbol).tag(s)
                }
            }
        } label: {
            Image(systemName: model.settings.ambientSound == .off ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Theme.surface))
                .overlay(Circle().strokeBorder(Theme.hairline))
        }
        .accessibilityLabel("Focus sound")
    }
}

/// "Are you sure?" sheet. Strict sessions require holding a button.
struct EndSessionSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let session: ActiveSession

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Theme.hairline).frame(width: 40, height: 5).padding(.top, 10)
            MascotView(mascot: session.mascot, mood: .sad, size: 140, showDecoration: false, motion: .breathe)
            Text(session.strict ? "Pebble-level discipline, remember?" : "End this session early?")
                .font(.rounded(.title2, weight: .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("You've focused for \(Format.longDuration(minutes: max(1, Int(session.elapsed() / 60)))). \(Format.longDuration(minutes: max(1, Int(session.remaining() / 60)))) to go. Minutes you've done still count.")
                .font(.rounded(.subheadline, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            Spacer(minLength: 4)
            Button("Keep going") { dismiss() }
                .buttonStyle(PrimaryButtonStyle(tint: session.mascot.accent, foreground: .white))
            if session.strict {
                HoldToConfirmButton(title: "Hold 5 seconds to give up", holdingTitle: "Are you really sure\u{2026}", duration: 5, tint: Theme.danger, foreground: .white) {
                    dismiss()
                    model.endEarly()
                }
            } else {
                Button("End session") {
                    dismiss()
                    model.endEarly()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(.horizontal, Theme.pagePadding)
        .padding(.bottom, 12)
        .pageBackground()
    }
}

/// Shown after giving up.
struct GaveUpSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let record: FocusSessionRecord

    var body: some View {
        VStack(spacing: 14) {
            Capsule().fill(Theme.hairline).frame(width: 40, height: 5).padding(.top, 10)
            MascotView(mascot: record.mascot, mood: .sad, size: 130, showDecoration: false, motion: .breathe)
            Text("That's okay")
                .font(.rounded(.title2, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text(record.mascot.line(from: record.mascot.gaveUpLines, seed: record.focusedSeconds))
                .font(.rounded(.body, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
            if record.focusedSeconds >= 60 {
                TraitChip(title: "+\(Format.longDuration(minutes: record.focusedMinutes)) still counted", symbol: "checkmark.circle.fill", tint: Theme.success, background: Theme.surface)
            }
            Spacer(minLength: 4)
            Button("Got it") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, Theme.pagePadding)
        .padding(.bottom, 12)
        .pageBackground()
    }
}
