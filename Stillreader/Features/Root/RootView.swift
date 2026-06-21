import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.dark.rawValue
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTab: RootTab = .inbox

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                TabletRootView()
            } else {
                phoneTabView
            }
        }
    }

    private var phoneTabView: some View {
        TabView(selection: $selectedTab) {
            Tab("Inbox", systemImage: "tray", value: RootTab.inbox) {
                InboxView()
            }
            Tab("Feeds", systemImage: "dot.radiowaves.up.forward", value: RootTab.feeds) {
                FeedsListView()
            }
            Tab("Links", systemImage: "link", value: RootTab.links) {
                lazyTab(.links) { LinksView() }
            }
            Tab("Search", systemImage: "magnifyingglass", value: RootTab.search) {
                lazyTab(.search) { SearchView() }
            }
            Tab("Settings", systemImage: "gear", value: RootTab.settings) {
                SettingsView()
            }
        }
        .preferredColorScheme(AppAppearance(rawValue: appAppearance)?.colorScheme)
        .background(StillPalette.screenBackground(colorScheme).ignoresSafeArea())
    }

    @ViewBuilder
    private func lazyTab<Content: View>(_ tab: RootTab, @ViewBuilder content: () -> Content) -> some View {
        if selectedTab == tab {
            content()
        } else {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
        }
    }
}
