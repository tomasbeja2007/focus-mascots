import DeviceActivity
import FamilyControls
import ManagedSettings
import SwiftUI

/// Renders real Screen Time data inside Focus Crew's Insights tab.
/// This extension runs in a privacy sandbox: the data never leaves it.
@main
struct FocusCrewReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { model in
            TotalActivityView(model: model)
        }
    }
}

struct AppUsage: Identifiable {
    let id: String
    let name: String
    let token: ApplicationToken?
    let duration: TimeInterval
    let pickups: Int
}

struct ActivityReportModel {
    var total: TimeInterval = 0
    var pickups: Int = 0
    var apps: [AppUsage] = []
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (ActivityReportModel) -> TotalActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReportModel {
        var model = ActivityReportModel()
        var byApp: [String: AppUsage] = [:]
        for await deviceData in data {
            for await segment in deviceData.activitySegments {
                model.total += segment.totalActivityDuration
                for await category in segment.categories {
                    for await app in category.applications {
                        let name = app.application.localizedDisplayName ?? app.application.bundleIdentifier ?? "App"
                        let key = app.application.bundleIdentifier ?? name
                        let previous = byApp[key]
                        byApp[key] = AppUsage(
                            id: key,
                            name: name,
                            token: app.application.token,
                            duration: (previous?.duration ?? 0) + app.totalActivityDuration,
                            pickups: (previous?.pickups ?? 0) + app.numberOfPickups
                        )
                        model.pickups += app.numberOfPickups
                    }
                }
            }
        }
        model.apps = byApp.values.sorted { $0.duration > $1.duration }.prefix(6).map { $0 }
        return model
    }
}

struct TotalActivityView: View {
    let model: ActivityReportModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(format(model.total))
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("today")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.inkSecondary)
                Spacer()
                Label("\(model.pickups)", systemImage: "iphone.gen3")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.inkSecondary)
            }
            if model.apps.isEmpty {
                Text("No app usage recorded yet today.")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(Theme.inkTertiary)
            } else {
                let top = max(1, model.apps.first?.duration ?? 1)
                ForEach(model.apps) { app in
                    HStack(spacing: 12) {
                        Group {
                            if let token = app.token {
                                Label(token)
                                    .labelStyle(.iconOnly)
                            } else {
                                Image(systemName: "app.fill")
                            }
                        }
                        .frame(width: 30, height: 30)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(app.name)
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                                Spacer()
                                Text(format(app.duration))
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundStyle(Theme.inkSecondary)
                            }
                            GeometryReader { geo in
                                Capsule()
                                    .fill(Color("BlobAccent"))
                                    .frame(width: max(6, geo.size.width * app.duration / top), height: 6)
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func format(_ t: TimeInterval) -> String {
        let minutes = Int(t / 60)
        let h = minutes / 60, m = minutes % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}
