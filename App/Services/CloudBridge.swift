import Foundation

/// Mirrors the app state into iCloud key-value storage so the Mac companion can
/// show the running session next to the notch.
enum CloudBridge {
    static let snapshotKey = "crew.snapshot.v1"

    static func publish(_ snapshot: CrewSnapshot, enabled: Bool) {
        let store = NSUbiquitousKeyValueStore.default
        guard enabled else {
            store.removeObject(forKey: snapshotKey)
            store.synchronize()
            return
        }
        guard let data = try? SharedFile<CrewSnapshot>.encoder.encode(snapshot) else { return }
        store.set(data, forKey: snapshotKey)
        store.synchronize()
    }
}
