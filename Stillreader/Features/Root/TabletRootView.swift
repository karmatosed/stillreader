import SwiftUI

struct TabletRootView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.dark.rawValue
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab: RootTab = .inbox
    @State private var inboxDetail: InboxDetailSelection?
    @State private var searchDetail: InboxDetailSelection?
    @State private var selectedFeedID: String?
    @State private var selectedLinkID: String?

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } content: {
            contentColumn
                .navigationSplitViewColumnWidth(min: 320, ideal: 380, max: 480)
        } detail: {
            detailColumn
        }
        .navigationSplitViewStyle(.balanced)
        .preferredColorScheme(AppAppearance(rawValue: appAppearance)?.colorScheme)
        .background(StillPalette.screenBackground(colorScheme).ignoresSafeArea())
        .onChange(of: selectedTab) { _, _ in
            clearSelectionsForTabChange()
        }
    }

    private var sidebar: some View {
        List {
            ForEach(RootTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Label(tab.title, systemImage: tab.systemImage)
                        .foregroundStyle(
                            selectedTab == tab
                                ? StillPalette.primaryText(colorScheme)
                                : StillPalette.secondaryText(colorScheme)
                        )
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    selectedTab == tab
                        ? StillPalette.selectedChipFill(colorScheme).opacity(0.35)
                        : Color.clear
                )
                .accessibilityIdentifier("sidebar-\(tab.rawValue)")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Stillreader")
    }

    @ViewBuilder
    private var contentColumn: some View {
        NavigationStack {
            switch selectedTab {
            case .inbox:
                InboxView(selectedDetail: $inboxDetail)
            case .feeds:
                FeedsListView(selectedFeedID: $selectedFeedID)
            case .links:
                LinksView(selectedLinkID: $selectedLinkID)
            case .search:
                SearchView(selectedDetail: $searchDetail)
            case .settings:
                SettingsView()
            }
        }
    }

    @ViewBuilder
    private var detailColumn: some View {
        switch selectedTab {
        case .inbox:
            InboxDetailPane(selection: inboxDetail)
        case .feeds:
            if let selectedFeedID,
               let feed = appState.feeds.first(where: { $0.id == selectedFeedID }) {
                NavigationStack {
                    FeedDetailView(feed: feed)
                }
            } else {
                SplitDetailPlaceholder(
                    "Feeds",
                    message: "Select a feed to view articles",
                    systemImage: "dot.radiowaves.up.forward"
                )
            }
        case .links:
            if let selectedLinkID {
                InboxDetailPane(selection: .link(linkID: selectedLinkID))
            } else {
                SplitDetailPlaceholder(
                    "Links",
                    message: "Select a saved link to read",
                    systemImage: "link"
                )
            }
        case .search:
            InboxDetailPane(selection: searchDetail)
        case .settings:
            SplitDetailPlaceholder(
                "Settings",
                message: "Adjust preferences in the middle column",
                systemImage: "gear"
            )
        }
    }

    private func clearSelectionsForTabChange() {
        inboxDetail = nil
        searchDetail = nil
        selectedFeedID = nil
        selectedLinkID = nil
    }
}
