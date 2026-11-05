import AppKit
import SwiftUI

@main
struct FocusCrewMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = MacModel.shared

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environment(model)
        } label: {
            if let s = model.current {
                Image(systemName: s.isPaused ? "pause.circle.fill" : "timer")
                Text(Format.clock(s.remaining(at: model.now)))
            } else {
                Image(systemName: "scope")
            }
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        Task { @MainActor in MacModel.shared.start() }
    }
}

/// The window that opens from the menu bar icon.
struct MenuContentView: View {
    @Environment(MacModel.self) private var model

    private let presets = [15, 25, 45, 60, 90]

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 14) {
            header
            if let s = model.current {
                sessionCard(s)
            } else {
                startCard
            }
            if let p = model.phone {
                todayCard(p)
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Show next to the notch", isOn: $model.showNotchIndicator)
                Toggle("Open at login", isOn: $model.launchAtLogin)
                if model.phone == nil {
                    Picker("Companion", selection: $model.preferredMascot) {
                        ForEach(Mascot.allCases) { m in Text(m.name).tag(m) }
                    }
                }
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .toggleStyle(.switch)
            .controlSize(.small)
            HStack {
                Text(model.phone == nil ? "Open Focus Crew on your iPhone with the same iCloud account to sync." : "Synced with your iPhone via iCloud")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(model.mascot.avatarAsset(model.current == nil ? .happy : .focused))
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text("Focus Crew")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                Text(model.phone.map { "Hi \($0.name)! \(model.mascot.name) is here." } ?? "\(model.mascot.name) is here.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let streak = model.phone?.streak, streak > 0 {
                Label("\(streak)", systemImage: "flame.fill")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.orange)
            }
        }
    }

    private func sessionCard(_ s: ActiveSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(Format.clock(s.remaining(at: model.now)))
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                Spacer()
                Text(model.isLocal ? "On this Mac" : "On iPhone")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            if !s.intention.isEmpty {
                Text(s.intention)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            ProgressView(value: s.progress(at: model.now))
                .tint(s.mascot.accent)
            if model.isLocal {
                HStack {
                    Button(s.isPaused ? "Resume" : "Pause") { model.togglePause() }
                    Button("End session", role: .destructive) { model.endLocal() }
                }
                .controlSize(.regular)
            } else {
                Text("Pause or end it from your iPhone.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(s.mascot.tint.opacity(0.35)))
    }

    private var startCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Start a focus session")
                .font(.system(size: 13, weight: .bold, design: .rounded))
            HStack(spacing: 6) {
                ForEach(presets, id: \.self) { p in
                    Button {
                        model.localMinutes = p
                    } label: {
                        Text("\(p)m")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(model.localMinutes == p ? Color.primary : Color.primary.opacity(0.08))
                            )
                            .foregroundStyle(model.localMinutes == p ? Color(nsColor: .windowBackgroundColor) : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            Button {
                model.startLocal()
            } label: {
                Label("Focus for \(model.localMinutes) minutes", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(model.mascot.accent)
            .controlSize(.large)
        }
    }

    private func todayCard(_ p: CrewSnapshot) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
                Text(Format.duration(seconds: p.todayFocusSeconds)).font(.system(size: 18, weight: .heavy, design: .rounded))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Goal").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
                Text(Format.duration(minutes: p.dailyGoalMinutes)).font(.system(size: 18, weight: .heavy, design: .rounded))
            }
            Spacer()
            ZStack {
                ProgressRing(progress: p.goalProgress, lineWidth: 5, tint: p.mascot.accent, track: Color.primary.opacity(0.08))
                Text("\(Int(p.goalProgress * 100))%").font(.system(size: 10, weight: .heavy, design: .rounded))
            }
            .frame(width: 40, height: 40)
        }
    }
}
