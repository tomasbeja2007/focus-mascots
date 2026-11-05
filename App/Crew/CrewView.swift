import SwiftUI

/// The Crew tab: your companion, the rest of the crew and badges.
struct CrewView: View {
    @Environment(AppModel.self) private var model
    @State private var detail: Mascot?
    @State private var showSettings = false
    @State private var showAllBadges = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    companionCard
                    SectionHeader(title: "The crew")
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(Mascot.allCases) { m in
                            CrewMemberCard(mascot: m, isCompanion: m == model.mascot, bond: model.stats.bond(with: m)) {
                                detail = m
                            }
                        }
                    }
                    SectionHeader(title: "Badges", trailing: "See all", action: { showAllBadges = true })
                        .padding(.top, 6)
                    badgesPreview
                }
                .padding(.horizontal, Theme.pagePadding)
                .padding(.bottom, 32)
            }
            .pageBackground()
            .navigationTitle("Your crew")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(item: $detail) { m in
                MascotDetailView(mascot: m)
                    .environment(model)
                    .presentationCornerRadius(32)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView().environment(model)
            }
            .navigationDestination(isPresented: $showAllBadges) {
                AchievementsView()
            }
        }
    }

    private var companionCard: some View {
        let m = model.mascot
        let bond = model.stats.bond(with: m)
        return VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 8) {
                MascotView(mascot: m, mood: m.restingMood, size: 150, motion: .float)
                VStack(alignment: .leading, spacing: 6) {
                    Text("YOUR COMPANION")
                        .font(.rounded(.caption2, weight: .heavy))
                        .tracking(1.2)
                        .foregroundStyle(m.accent)
                    Text(m.name)
                        .font(.rounded(size: 34, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Text(m.title)
                        .font(.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                    TraitChip(title: m.trait, symbol: m.traitSymbol, tint: m.accent, background: Theme.surface)
                }
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Bond level \(bond.level)")
                        .font(.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("· \(bond.title)")
                        .font(.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                    Spacer()
                    Text("\(bond.minutesToNext) min to Lv \(bond.level + 1)")
                        .font(.rounded(.caption, weight: .semibold))
                        .foregroundStyle(Theme.inkTertiary)
                }
                ProgressBar(progress: bond.progress, tint: m.accent, track: Theme.surface, height: 10)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 32, style: .continuous).fill(m.tint.opacity(0.6)))
    }

    private var badgesPreview: some View {
        let sorted = Achievement.allCases.sorted { a, b in
            let ua = model.isUnlocked(a), ub = model.isUnlocked(b)
            if ua != ub { return ua }
            return a.rawValue < b.rawValue
        }
        let unlockedCount = Achievement.allCases.filter { model.isUnlocked($0) }.count
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(unlockedCount) of \(Achievement.allCases.count) collected")
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }
            HStack(spacing: 10) {
                ForEach(sorted.prefix(5)) { a in
                    VStack(spacing: 6) {
                        BadgeIcon(achievement: a, unlocked: model.isUnlocked(a), size: 54)
                        Text(a.title)
                            .font(.rounded(.caption2, weight: .bold))
                            .foregroundStyle(model.isUnlocked(a) ? Theme.ink : Theme.inkTertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .cardStyle(radius: Theme.cornerLarge)
        .onTapGesture { showAllBadges = true }
    }
}

struct CrewMemberCard: View {
    let mascot: Mascot
    let isCompanion: Bool
    let bond: BondLevel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                MascotView(mascot: mascot, mood: mascot.restingMood, size: 118, motion: .still)
                Text(mascot.name)
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text(mascot.title)
                    .font(.rounded(.caption, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill").font(.system(size: 10, weight: .bold))
                    Text("Lv \(bond.level)")
                }
                .font(.rounded(.caption, weight: .bold))
                .foregroundStyle(mascot.accent)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(mascot.tint.opacity(0.7)))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous).fill(Theme.surface))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous)
                    .strokeBorder(isCompanion ? mascot.accent : Theme.hairline, lineWidth: isCompanion ? 2.5 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if isCompanion {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(mascot.accent)
                        .background(Circle().fill(Theme.surface))
                        .padding(10)
                }
            }
        }
        .buttonStyle(PressableStyle())
    }
}

/// Mascot profile sheet: moods, story, stats and "make companion".
struct MascotDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let mascot: Mascot
    @State private var mood: MascotMood = .happy

    var body: some View {
        let bond = model.stats.bond(with: mascot)
        let sessions = model.stats.focusSessions.filter { $0.mascot == mascot && $0.completed }.count
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    MascotView(mascot: mascot, mood: mood, size: 250, motion: mood == .excited ? .bounce : .float)
                        .padding(.top, 20)
                        .onTapGesture { cycleMood() }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MascotMood.allCases.filter { $0 != .blink }, id: \.self) { m in
                                Button {
                                    Haptics.select()
                                    withAnimation(.spring) { mood = m }
                                } label: {
                                    Text(m.rawValue.capitalized)
                                        .font(.rounded(.caption, weight: .bold))
                                        .foregroundStyle(mood == m ? Theme.inkInverse : Theme.ink)
                                        .padding(.horizontal, 12).frame(height: 30)
                                        .background(Capsule().fill(mood == m ? mascot.accent : Theme.surface))
                                }
                                .buttonStyle(PressableStyle())
                            }
                        }
                        .padding(.horizontal, Theme.pagePadding)
                    }
                    VStack(spacing: 6) {
                        Text(mascot.name)
                            .font(.rounded(size: 40, weight: .heavy))
                            .foregroundStyle(Theme.ink)
                        Text(mascot.title)
                            .font(.rounded(.title3, weight: .semibold))
                            .foregroundStyle(Theme.inkSecondary)
                        TraitChip(title: mascot.trait, symbol: mascot.traitSymbol, tint: mascot.accent, background: Theme.surface)
                            .padding(.top, 4)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\u{201C}\(mascot.tagline)\u{201D}")
                            .font(.rounded(.title3, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Text(mascot.bio)
                            .font(.rounded(.body, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Label(mascot.specialty, systemImage: "sparkles")
                            .font(.rounded(.subheadline, weight: .semibold))
                            .foregroundStyle(mascot.accent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle(radius: Theme.cornerLarge)
                    .padding(.horizontal, Theme.pagePadding)

                    HStack(spacing: 12) {
                        StatTile(value: "Lv \(bond.level)", label: bond.title, symbol: "heart.fill", tint: mascot.accent)
                        StatTile(value: Format.duration(minutes: bond.minutes), label: "focused together", symbol: "clock.fill", tint: mascot.accent)
                        StatTile(value: "\(sessions)", label: "sessions", symbol: "checkmark.circle.fill", tint: mascot.accent)
                    }
                    .padding(.horizontal, Theme.pagePadding)
                    .padding(.bottom, 16)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                companionButton
                    .padding(.horizontal, Theme.pagePadding)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
            }
            CircleIconButton(symbol: "xmark", size: 34, label: "Close") { dismiss() }
                .padding(16)
        }
        .background(LinearGradient(colors: [mascot.tint, mascot.wash, Theme.background], startPoint: .top, endPoint: .center).ignoresSafeArea())
        .onAppear { mood = mascot.restingMood == .happy ? .happy : mascot.restingMood }
    }

    @ViewBuilder
    private var companionButton: some View {
        if mascot == model.mascot {
                    Label("\(mascot.name) is your companion", systemImage: "checkmark.circle.fill")
                        .font(.rounded(.headline, weight: .bold))
                        .foregroundStyle(mascot.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(Capsule().fill(mascot.tint))
                } else {
                    Button("Make \(mascot.name) my companion") {
                        model.choose(mascot: mascot)
                        withAnimation(.spring) { mood = .excited }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(model.active != nil)
        }
    }

    private func cycleMood() {
        let all = MascotMood.allCases.filter { $0 != .blink }
        let i = all.firstIndex(of: mood) ?? 0
        Haptics.soft()
        withAnimation(.spring) { mood = all[(i + 1) % all.count] }
    }
}

struct AchievementsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let st = model.stats
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Achievement.allCases) { a in
                    let unlocked = model.isUnlocked(a)
                    let p = a.progress(stats: st, dailyGoalMinutes: model.settings.dailyGoalMinutes, scheduleCount: model.schedules.count)
                    VStack(spacing: 8) {
                        BadgeIcon(achievement: a, unlocked: unlocked, size: 64)
                        Text(a.title)
                            .font(.rounded(.headline, weight: .bold))
                            .foregroundStyle(unlocked ? Theme.ink : Theme.inkSecondary)
                        Text(a.detail)
                            .font(.rounded(.caption, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        if unlocked, let date = model.unlocked[a.rawValue] {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(.rounded(.caption2, weight: .bold))
                                .foregroundStyle(a.mascot.accent)
                        } else {
                            ProgressBar(progress: p.1 > 0 ? p.0 / p.1 : 0, tint: a.mascot.accent, track: Theme.surfaceMuted, height: 6)
                                .padding(.horizontal, 10)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 190)
                    .cardStyle(padding: 12, radius: Theme.cornerLarge)
                }
            }
            .padding(Theme.pagePadding)
        }
        .pageBackground()
        .navigationTitle("Badges")
    }
}
