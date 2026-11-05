import AppKit
import SwiftUI
import Foundation
import Observation
import ServiceManagement

/// State of the Mac companion: the iPhone's session (via iCloud) and sessions
/// started on the Mac itself.
@MainActor
@Observable
final class MacModel {
    static let shared = MacModel()

    /// Latest state published by the iPhone app.
    var phone: CrewSnapshot?
    /// A session started on this Mac.
    var local: ActiveSession?
    /// Ticks once a second while something is running, to drive the UI.
    var now = Date()
    /// Briefly shows a celebration after a session ends.
    var celebrating: Mascot?
    var expanded = false

    var showNotchIndicator: Bool {
        didSet { UserDefaults.standard.set(showNotchIndicator, forKey: Keys.showNotch); refreshPanel() }
    }
    var preferredMascot: Mascot {
        didSet { UserDefaults.standard.set(preferredMascot.rawValue, forKey: Keys.mascot) }
    }
    var launchAtLogin: Bool {
        didSet { applyLaunchAtLogin() }
    }
    var localMinutes: Int {
        didSet { UserDefaults.standard.set(localMinutes, forKey: Keys.minutes) }
    }

    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var celebratedIDs: Set<UUID> = []
    let panel = NotchPanelController()

    private enum Keys {
        static let showNotch = "showNotchIndicator"
        static let mascot = "preferredMascot"
        static let minutes = "localMinutes"
        static let local = "localSession"
    }

    init() {
        let d = UserDefaults.standard
        showNotchIndicator = d.object(forKey: Keys.showNotch) as? Bool ?? true
        preferredMascot = Mascot(rawValue: d.string(forKey: Keys.mascot) ?? "") ?? .orbit
        launchAtLogin = SMAppService.mainApp.status == .enabled
        localMinutes = d.object(forKey: Keys.minutes) as? Int ?? 25
        if let data = d.data(forKey: Keys.local), let s = try? SharedFile<ActiveSession>.decoder.decode(ActiveSession.self, from: data) {
            local = s
        }
    }

    // MARK: Derived

    var mascot: Mascot { current?.mascot ?? phone?.mascot ?? preferredMascot }

    /// The session to show: one started on the Mac wins, otherwise the iPhone's.
    var current: ActiveSession? {
        if let local, !local.isFinished(at: now) { return local }
        if let p = phone?.active, !p.isFinished(at: now) { return p }
        return nil
    }

    var isLocal: Bool { current != nil && current?.id == local?.id }

    var menuBarTitle: String {
        guard let s = current else { return "" }
        return Format.clock(s.remaining(at: now))
    }

    // MARK: Lifecycle

    func start() {
        if UserDefaults.standard.bool(forKey: "demoSession") {
            local = ActiveSession(kind: .focus, minutes: 25, mascot: .orbit, intention: "Design review", start: Date().addingTimeInterval(-7 * 60 - 18))
            phone = CrewSnapshot.placeholder
            showNotchPreview()
        }
        let store = NSUbiquitousKeyValueStore.default
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { _ in
            Task { @MainActor in MacModel.shared.readCloud() }
        }
        store.synchronize()
        readCloud()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in MacModel.shared.tick() }
        }
        RunLoop.main.add(timer!, forMode: .common)
        tick()
    }

    func readCloud() {
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: "crew.snapshot.v1"),
              let snapshot = try? SharedFile<CrewSnapshot>.decoder.decode(CrewSnapshot.self, from: data) else { return }
        phone = snapshot
        refreshPanel()
    }

    private func tick() {
        now = Date()
        // Celebrate sessions that just ended.
        for s in [local, phone?.active].compactMap({ $0 }) where s.isFinished(at: now) && !celebratedIDs.contains(s.id) {
            celebratedIDs.insert(s.id)
            // Only celebrate sessions that ended recently (not stale state from hours ago).
            if now.timeIntervalSince(s.endsAt) < 120 { celebrate(s) }
            if s.id == local?.id { local = nil; saveLocal() }
        }
        refreshPanel()
    }

    private func celebrate(_ s: ActiveSession) {
        celebrating = s.mascot
        if s.kind == .focus, let url = Bundle.main.url(forResource: "chime", withExtension: "wav") {
            NSSound(contentsOf: url, byReference: true)?.play()
        }
        refreshPanel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            MacModel.shared.celebrating = nil
            MacModel.shared.refreshPanel()
        }
    }

    func refreshPanel() {
        let visible = showNotchIndicator && (current != nil || celebrating != nil)
        panel.update(visible: visible, expanded: expanded)
    }

    // MARK: Local sessions

    func startLocal(minutes: Int? = nil) {
        let m = minutes ?? localMinutes
        local = ActiveSession(kind: .focus, minutes: m, mascot: phone?.mascot ?? preferredMascot)
        local?.deviceName = "Mac"
        saveLocal()
        expanded = false
        tick()
    }

    func togglePause() {
        guard var s = local else { return }
        if let pausedAt = s.pausedAt {
            let d = Date().timeIntervalSince(pausedAt)
            s.pausedSeconds += d
            s.endsAt = s.endsAt.addingTimeInterval(d)
            s.pausedAt = nil
        } else {
            s.pausedAt = Date()
        }
        local = s
        saveLocal()
        tick()
    }

    func endLocal() {
        guard let s = local else { return }
        celebratedIDs.insert(s.id)
        local = nil
        saveLocal()
        expanded = false
        tick()
    }

    private func saveLocal() {
        let d = UserDefaults.standard
        if let local, let data = try? SharedFile<ActiveSession>.encoder.encode(local) {
            d.set(data, forKey: Keys.local)
        } else {
            d.removeObject(forKey: Keys.local)
        }
    }

    @ObservationIgnored private var previewWindow: NSWindow?

    /// Opens a window that renders the notch layout (debug / screenshots).
    func showNotchPreview() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 668, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Notch preview"
        window.contentView = NSHostingView(rootView: NotchPreviewWindowContent())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        previewWindow = window
    }

    private func applyLaunchAtLogin() {
        do {
            if launchAtLogin {
                if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
            } else {
                if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            }
        } catch {
            // The user can manage this in System Settings › General › Login Items.
        }
    }
}
