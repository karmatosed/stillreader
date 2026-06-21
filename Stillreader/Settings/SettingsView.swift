import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("inboxGroupedByFeed") private var inboxGroupedByFeed = false

    var body: some View {
        Form {
            Section("Storage") {
                LabeledContent("Location") {
                    Text(storageLabel)
                        .foregroundStyle(appState.iCloudAvailable ? .green : .orange)
                }
                LabeledContent("iCloud sync") {
                    Text(appState.iCloudAvailable ? "On" : "Off")
                }
                LabeledContent("Schema version") { Text("1") }
            }

            Section("Preferences") {
                Toggle("Group inbox by feed", isOn: $inboxGroupedByFeed)
                Text("Articles cached for 30 days")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if !appState.syncIssues.isEmpty {
                Section("Sync issues") {
                    ForEach(appState.syncIssues, id: \.self) { issue in
                        Text(issue).font(.footnote)
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }

    private var storageLabel: String {
        switch appState.storageLocation {
        case .iCloudDrive: return "iCloud Drive"
        case .appGroup: return "App Group (this device)"
        case .localFallback: return "Local only"
        }
    }
}
