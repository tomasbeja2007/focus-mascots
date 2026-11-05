import SwiftUI

@main
struct FocusCrewApp: App {
    @State private var model = AppModel.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        DemoMode.prepare(AppModel.shared)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .appearance(model.settings.appearance)
                .onOpenURL { model.handle($0) }
                .onAppear { model.bootstrap() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.reconcile() }
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        ZStack {
            #if DEBUG
            if let screen = DemoMode.screen {
                DemoScreenView(screen: screen)
            } else {
                content
            }
            #else
            content
            #endif
        }
        .tint(Theme.ink)
        .fullScreenCover(isPresented: $model.showSession) {
            SessionContainerView()
                .environment(model)
                .appearance(model.settings.appearance)
        }
        .sheet(item: $model.abandoned) { record in
            GaveUpSheet(record: record)
                .environment(model)
                .presentationDetents([.medium])
                .presentationCornerRadius(32)
        }
        .overlay(alignment: .top) {
            if let toast = model.toast {
                ToastView(text: toast, mascot: model.mascot)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: toast) {
                        try? await Task.sleep(nanoseconds: 2_800_000_000)
                        withAnimation(.spring) { model.toast = nil }
                    }
                    .onTapGesture { withAnimation(.spring) { model.toast = nil } }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: model.toast)
    }

    @ViewBuilder
    private var content: some View {
        if model.hasOnboarded {
            MainTabView()
                .transition(.opacity)
        } else {
            OnboardingFlow()
                .transition(.opacity)
        }
    }
}

struct MainTabView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.selectedTab) {
            FocusHomeView()
                .sessionBarInset()
                .tabItem { Label("Focus", systemImage: "scope") }
                .tag(AppTab.focus)
            BlocksView()
                .sessionBarInset()
                .tabItem { Label("Blocks", systemImage: "shield.lefthalf.filled") }
                .tag(AppTab.blocks)
            InsightsView()
                .sessionBarInset()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                .tag(AppTab.insights)
            CrewView()
                .sessionBarInset()
                .tabItem { Label("Crew", systemImage: "face.smiling.inverse") }
                .tag(AppTab.crew)
        }
        .tint(model.mascot.accent)
    }
}

private struct SessionBarInset: ViewModifier {
    @Environment(AppModel.self) private var model

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if model.active != nil && !model.showSession {
                    MiniSessionBar()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: model.active?.id)
    }
}

extension View {
    func sessionBarInset() -> some View { modifier(SessionBarInset()) }
}

/// Floating bar above the tab bar while a session runs in the background of the UI.
struct MiniSessionBar: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let s = model.active {
            Button {
                model.showSession = true
            } label: {
                HStack(spacing: 12) {
                    MascotAvatar(mascot: s.mascot, size: 38)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(s.kind == .rest ? "On a break" : (s.isPaused ? "Paused" : "Focusing"))
                            .font(.rounded(.caption, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                        Text(s.intention.isEmpty ? "with \(s.mascot.name)" : s.intention)
                            .font(.rounded(.subheadline, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    if s.isPaused {
                        Text(Format.clock(s.remaining()))
                            .font(.rounded(.title3, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                    } else {
                        Text(timerInterval: s.countdownRange, countsDown: true)
                            .font(.rounded(.title3, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 84, alignment: .trailing)
                    }
                }
                .padding(.leading, 8)
                .padding(.trailing, 18)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(red: 0.12, green: 0.12, blue: 0.14)))
                .shadow(color: .black.opacity(0.2), radius: 14, y: 6)
            }
            .buttonStyle(PressableStyle())
        }
    }
}
