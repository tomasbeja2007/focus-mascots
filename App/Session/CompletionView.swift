import SwiftUI

/// The celebration after a finished session.
struct CompletionView: View {
    @Environment(AppModel.self) private var model
    let summary: CompletionSummary

    @State private var appeared = false
    @State private var bondProgress: Double = 0

    private var mascot: Mascot { summary.record.mascot }

    var body: some View {
        ZStack {
            LinearGradient(colors: [mascot.tint, mascot.wash, Theme.background], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Text("SESSION COMPLETE")
                        .font(.rounded(.caption, weight: .heavy))
                        .tracking(1.5)
                        .foregroundStyle(mascot.accent)
                        .padding(.top, 28)
                    MascotView(mascot: mascot, mood: .excited, size: 230, motion: .bounce)
                        .scaleEffect(appeared ? 1 : 0.5)
                    Text("+\(Format.longDuration(minutes: summary.record.focusedMinutes))")
                        .font(.rounded(size: 54, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Text(summary.line)
                        .font(.rounded(.title3, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    if !summary.record.intention.isEmpty {
                        Label(summary.record.intention, systemImage: "checkmark.circle.fill")
                            .font(.rounded(.subheadline, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Capsule().fill(Theme.surface))
                    }

                    HStack(spacing: 12) {
                        StatTile(value: Format.duration(seconds: summary.todaySeconds), label: "today", symbol: "sun.max.fill", tint: Theme.warning)
                        StatTile(value: "\(summary.streak)", label: summary.streak == 1 ? "day streak" : "day streak", symbol: "flame.fill", tint: Theme.flame)
                        StatTile(value: "\(Int(min(1, Double(summary.todaySeconds) / Double(max(1, summary.goalMinutes * 60))) * 100))%", label: "of goal", symbol: "target", tint: mascot.accent)
                    }
                    .padding(.top, 4)

                    bondCard

                    if !summary.newAchievements.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(summary.newAchievements.count == 1 ? "New badge!" : "New badges!")
                                .font(.rounded(.headline, weight: .bold))
                                .foregroundStyle(Theme.ink)
                            ForEach(summary.newAchievements) { a in
                                HStack(spacing: 12) {
                                    BadgeIcon(achievement: a, unlocked: true, size: 48)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(a.title).font(.rounded(.headline, weight: .bold)).foregroundStyle(Theme.ink)
                                        Text(a.detail).font(.rounded(.footnote, weight: .medium)).foregroundStyle(Theme.inkSecondary)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .cardStyle(radius: Theme.cornerLarge)
                    }
                }
                .padding(.horizontal, Theme.pagePadding)
                .padding(.bottom, 140)
            }
            VStack(spacing: 10) {
                Spacer()
                Button {
                    model.startBreak()
                } label: {
                    Label("Take a \(model.settings.breakMinutes)-min break", systemImage: "cup.and.saucer.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
                Button("Done") {
                    model.completion = nil
                    model.showSession = false
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, Theme.pagePadding)
            .padding(.bottom, 12)
            .background(
                LinearGradient(colors: [Theme.background.opacity(0), Theme.background], startPoint: .top, endPoint: .center)
                    .frame(height: 170)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            )
            ConfettiView(count: 120).ignoresSafeArea()
        }
        .onAppear {
            bondProgress = summary.leveledUp ? 0 : summary.bondBefore.progress
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { appeared = true }
            withAnimation(.easeOut(duration: 1.2).delay(0.5)) { bondProgress = summary.bondAfter.progress }
        }
    }

    private var bondCard: some View {
        HStack(spacing: 14) {
            MascotAvatar(mascot: mascot, size: 52)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(summary.leveledUp ? "Level up! Lv \(summary.bondAfter.level)" : "Bond with \(mascot.name) · Lv \(summary.bondAfter.level)")
                        .font(.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(summary.leveledUp ? mascot.accent : Theme.ink)
                    Spacer()
                    Text(summary.bondAfter.title)
                        .font(.rounded(.caption, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                }
                ProgressBar(progress: bondProgress, tint: mascot.accent, track: mascot.tint, height: 10)
                Text("\(summary.bondAfter.minutesToNext) min to level \(summary.bondAfter.level + 1)")
                    .font(.rounded(.caption, weight: .medium))
                    .foregroundStyle(Theme.inkTertiary)
            }
        }
        .cardStyle(radius: Theme.cornerLarge)
    }
}

/// Round badge used for achievements.
struct BadgeIcon: View {
    let achievement: Achievement
    let unlocked: Bool
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle()
                .fill(unlocked ? achievement.mascot.tint : Theme.surfaceMuted)
            Circle()
                .strokeBorder(unlocked ? achievement.mascot.accent.opacity(0.5) : Theme.hairline, lineWidth: size * 0.05)
            Image(systemName: unlocked ? achievement.symbol : "lock.fill")
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(unlocked ? achievement.mascot.accent : Theme.inkTertiary)
        }
        .frame(width: size, height: size)
    }
}
