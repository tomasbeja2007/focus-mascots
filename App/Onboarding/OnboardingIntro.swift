import SwiftUI

/// First screen: the whole crew, like the poster.
struct WelcomeStep: View {
    let onNext: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            VStack(spacing: 10) {
                Text("Meet your")
                    .font(.rounded(.title2, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
                Text("Focus Crew")
                    .font(.rounded(size: 44, weight: .heavy))
                    .foregroundStyle(Theme.ink)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)

            CrewLineup(appeared: appeared)
                .padding(.top, 28)

            Text("Five tiny companions that help you put the phone down, block distractions and actually get things done.")
                .font(.rounded(.body, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 28)
                .opacity(appeared ? 1 : 0)

            Spacer()

            VStack(spacing: 12) {
                Button("Get started", action: onNext)
                    .buttonStyle(PrimaryButtonStyle())
                Text("Takes about 3 minutes. Everything stays on your device.")
                    .font(.rounded(.footnote))
                    .foregroundStyle(Theme.inkTertiary)
            }
            .padding(.horizontal, Theme.pagePadding)
            .padding(.bottom, 12)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) { appeared = true }
        }
    }
}

/// The five mascots in two rows, popping in one after another.
struct CrewLineup: View {
    var appeared: Bool
    var size: CGFloat = 132

    var body: some View {
        VStack(spacing: -size * 0.16) {
            HStack(spacing: -size * 0.12) {
                member(.orbit, index: 0, mood: .happy)
                member(.spark, index: 1, mood: .happy)
                member(.leaf, index: 2, mood: .sleepy)
            }
            HStack(spacing: -size * 0.04) {
                member(.pebble, index: 3, mood: .focused)
                member(.blob, index: 4, mood: .happy)
            }
        }
    }

    private func member(_ m: Mascot, index: Int, mood: MascotMood) -> some View {
        VStack(spacing: 2) {
            MascotView(mascot: m, mood: mood, size: size, motion: .float)
            Text(m.name)
                .font(.rounded(.subheadline, weight: .bold))
                .foregroundStyle(Theme.ink)
        }
        .scaleEffect(appeared ? 1 : 0.4)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.55, dampingFraction: 0.62).delay(0.15 + Double(index) * 0.09), value: appeared)
    }
}

/// Value-proposition pages before the questions.
struct IntroStep: View {
    let mascot: Mascot
    let mood: MascotMood
    let title: String
    let subtitle: String
    let bullets: [(String, String)]
    let onNext: () -> Void

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .fill(mascot.wash)
                    MascotView(mascot: mascot, mood: mood, size: 230, motion: .float)
                }
                .frame(height: 260)

                Text(title)
                    .font(.rounded(.largeTitle, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.rounded(.body, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(bullets, id: \.1) { item in
                        HStack(spacing: 12) {
                            IconBadge(symbol: item.0, tint: mascot.accent, background: mascot.tint.opacity(0.6), size: 34)
                            Text(item.1)
                                .font(.rounded(.body, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                }
                .padding(.top, 4)
            }
        } footer: {
            Button("Continue", action: onNext)
                .buttonStyle(PrimaryButtonStyle())
        }
    }
}

struct NameStep: View {
    @Binding var name: String
    let onNext: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 20) {
                HostBubble(mascot: .orbit, text: "Hi! I'm Orbit. Before we start\u{2026}", mood: .happy)
                Text("What should we call you?")
                    .font(.rounded(.largeTitle, weight: .bold))
                    .foregroundStyle(Theme.ink)
                TextField("Your first name", text: $name)
                    .font(.rounded(.title2, weight: .semibold))
                    .textContentType(.givenName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.continue)
                    .focused($focused)
                    .onSubmit { if canContinue { onNext() } }
                    .padding(.horizontal, 20)
                    .frame(height: 64)
                    .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.surface))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                            .strokeBorder(focused ? Theme.ink : Theme.hairline, lineWidth: focused ? 2 : 1)
                    )
                Text("Your crew will use it to cheer you on.")
                    .font(.rounded(.footnote))
                    .foregroundStyle(Theme.inkTertiary)
            }
        } footer: {
            Button("Continue", action: onNext)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canContinue)
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { focused = true } }
    }

    private var canContinue: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
}
