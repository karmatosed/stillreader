import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("inboxGroupedByFeed") private var inboxGroupedByFeed = false
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.dark.rawValue
    @State private var isLoadingDemoFeeds = false
    @State private var demoFeedMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Storage") {
                    Button("Reload library") {
                        Task { await appState.loadLibrary() }
                    }
                    Button("Reset all data", role: .destructive) {
                        Task { await appState.resetAllData() }
                    }
                    LabeledContent("Feeds loaded") {
                        Text("\(appState.feeds.count)")
                    }
                    LabeledContent("Articles cached") {
                        Text("\(appState.articles.count)")
                    }
                    LabeledContent("Location") {
                        Text(storageLabel)
                            .foregroundStyle(appState.iCloudAvailable ? .green : .orange)
                    }
                    LabeledContent("iCloud sync") {
                        Text(appState.iCloudAvailable ? "On" : "Off")
                    }
                    LabeledContent("Schema version") { Text("1") }
                }

                Section("Feeds") {
                    Button("Load demo feeds") {
                        loadDemoFeeds()
                    }
                    .disabled(isLoadingDemoFeeds)
                    Text("The Verge, Hacker News, BBC Technology, and Daring Fireball.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Appearance") {
                    Picker("Theme", selection: $appAppearance) {
                        ForEach(AppAppearance.allCases) { mode in
                            Text(mode.label).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("Dark mode uses a calm monochrome palette — no system accent colors.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Preferences") {
                    Toggle("Group inbox by feed", isOn: $inboxGroupedByFeed)
                        .onChange(of: inboxGroupedByFeed) { _, _ in
                            appState.reloadInboxLayout()
                        }
                    Text("Articles cached for 30 days")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !appState.feedErrors.isEmpty {
                    Section("Feed fetch errors") {
                        ForEach(Array(appState.feedErrors.keys.sorted()), id: \.self) { feedID in
                            if let feed = appState.feeds.first(where: { $0.id == feedID }),
                               let error = appState.feedErrors[feedID] {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(feed.title).font(.footnote.bold())
                                    Text(error).font(.footnote).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
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
            .alert("Demo feeds", isPresented: Binding(
                get: { demoFeedMessage != nil },
                set: { if !$0 { demoFeedMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(demoFeedMessage ?? "")
            }
        }
    }

    private func loadDemoFeeds() {
        guard !isLoadingDemoFeeds else { return }
        isLoadingDemoFeeds = true
        Task {
            defer { isLoadingDemoFeeds = false }
            do {
                let result = try await appState.loadDemoFeeds()
                var message = "Added \(result.imported) feed\(result.imported == 1 ? "" : "s")"
                if result.skipped > 0 {
                    message += ", skipped \(result.skipped) duplicate\(result.skipped == 1 ? "" : "s")"
                }
                message += "."
                if !appState.articles.isEmpty {
                    message += "\n\n\(appState.articles.count) articles loaded."
                } else if !appState.feedErrors.isEmpty {
                    message += "\n\nCould not fetch articles — see Feed fetch errors below."
                }
                demoFeedMessage = message
            } catch {
                demoFeedMessage = error.localizedDescription
            }
        }
    }

    private var storageLabel: String {
        switch appState.storageLocation {
        case .iCloudDrive: return "iCloud Drive"
        case .appGroup: return "App Group (this device)"
        case .localFallback: return "Local only"
        }
    }
}
