import Foundation

/// Shared container used by the app and all of its extensions.
///
/// The identifier comes from the `AppGroupIdentifier` Info.plist key, which is
/// filled from `FC_APP_GROUP_ID` in `Configs/Shared.xcconfig`, so it only has to
/// be changed in one place.
enum AppGroup {
    static let fallbackIdentifier = "group.com.focuscrew.app"

    static var identifier: String {
        let value = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String
        guard let value, !value.isEmpty, !value.contains("$(") else { return fallbackIdentifier }
        return value
    }

    static var defaults: UserDefaults {
        #if os(macOS)
        return .standard
        #else
        return UserDefaults(suiteName: identifier) ?? .standard
        #endif
    }

    /// Directory that every target can read and write.
    static var containerURL: URL {
        #if os(macOS)
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = base.appendingPathComponent("FocusCrew", isDirectory: true)
        #else
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        #endif
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
}

/// A tiny Codable file store inside the App Group container.
///
/// Every value is a single JSON file, written atomically, so the app and its
/// extensions can read each other's state without a database.
struct SharedFile<Value: Codable> {
    let name: String

    var url: URL { AppGroup.containerURL.appendingPathComponent(name) }

    func load() -> Value? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? SharedFile.decoder.decode(Value.self, from: data)
    }

    func save(_ value: Value?) {
        guard let value else {
            try? FileManager.default.removeItem(at: url)
            return
        }
        guard let data = try? SharedFile.encoder.encode(value) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    static var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .secondsSince1970
        return e
    }

    static var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }
}

/// Names of every shared file, in one place.
enum SharedFiles {
    static let profile = SharedFile<UserProfile>(name: "profile.json")
    static let settings = SharedFile<AppSettings>(name: "settings.json")
    static let history = SharedFile<[FocusSessionRecord]>(name: "history.json")
    static let schedules = SharedFile<[BlockSchedule]>(name: "schedules.json")
    static let activeSession = SharedFile<ActiveSession>(name: "active-session.json")
    static let snapshot = SharedFile<CrewSnapshot>(name: "snapshot.json")
    static let unlocked = SharedFile<[String: Date]>(name: "achievements.json")
}
