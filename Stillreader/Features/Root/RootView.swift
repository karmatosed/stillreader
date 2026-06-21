import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.isReady {
                #if os(macOS)
                MacRootView()
                #else
                IOSRootView()
                #endif
            } else {
                ProgressView("Loading…")
            }
        }
        .task { await appState.bootstrap() }
    }
}

private struct IOSRootView: View {
    var body: some View {
        TabView {
            InboxView()
                .tabItem { Label("Inbox", systemImage: "tray") }
            FeedsListView()
                .tabItem { Label("Feeds", systemImage: "dot.radiowaves.up.forward") }
            LinksView()
                .tabItem { Label("Links", systemImage: "link") }
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
        }
    }
}

private struct MacRootView: View {
    @State private var section: AppSection? = .inbox

    var body: some View {
        NavigationSplitView {
            List(selection: $section) {
                NavigationLink(value: AppSection.inbox) {
                    Label("Inbox", systemImage: "tray")
                }
                NavigationLink(value: AppSection.feeds) {
                    Label("Feeds", systemImage: "dot.radiowaves.up.forward")
                }
                NavigationLink(value: AppSection.links) {
                    Label("Links", systemImage: "link")
                }
                NavigationLink(value: AppSection.search) {
                    Label("Search", systemImage: "magnifyingglass")
                }
                NavigationLink(value: AppSection.settings) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationTitle("Stillreader")
        } detail: {
            switch section ?? .inbox {
            case .inbox: InboxView()
            case .feeds: FeedsListView()
            case .links: LinksView()
            case .search: SearchView()
            case .settings: SettingsView()
            }
        }
    }
}
