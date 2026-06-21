import SwiftUI

struct FeedsListView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    @Binding private var selectedFeedID: String?
    private let usesSplitNavigation: Bool

    @State private var showingAddFeed = false
    @State private var showingImport = false
    @State private var isLoadingDemoFeeds = false
    @State private var demoFeedMessage: String?

    init() {
        _selectedFeedID = .constant(nil)
        usesSplitNavigation = false
    }

    init(selectedFeedID: Binding<String?>) {
        _selectedFeedID = selectedFeedID
        usesSplitNavigation = true
    }

    var body: some View {
        Group {
            if usesSplitNavigation {
                feedsList
            } else {
                NavigationStack {
                    feedsList
                }
            }
        }
    }

    private var feedsList: some View {
        List {
            if appState.feeds.isEmpty {
                ContentUnavailableView {
                    Label("No feeds", systemImage: "dot.radiowaves.up.forward")
                } description: {
                    Text("Add a feed, import OPML, or load demo feeds to get started.")
                } actions: {
                    Button("Load demo feeds") { loadDemoFeeds() }
                        .buttonStyle(.calmProminent)
                        .disabled(isLoadingDemoFeeds)
                        .accessibilityIdentifier("loadDemoFeedsButton")
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                ForEach(appState.feeds) { feed in
                    feedRow(feed)
                }
                .onDelete(perform: deleteFeeds)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(StillPalette.screenBackground(colorScheme))
        .id(appState.feeds.map(\.id).joined(separator: "-"))
        .navigationTitle("Feeds")
        .navigationBarTitleDisplayMode(usesSplitNavigation ? .inline : .large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Add feed") { showingAddFeed = true }
                    Button("Import OPML") { showingImport = true }
                    Button("Load demo feeds") { loadDemoFeeds() }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("feedsAddMenu")
            }
        }
        .sheet(isPresented: $showingAddFeed) {
            AddFeedView()
        }
        .sheet(isPresented: $showingImport) {
            OPMLImportView()
        }
        .alert("Demo feeds", isPresented: Binding(
            get: { demoFeedMessage != nil },
            set: { if !$0 { demoFeedMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(demoFeedMessage ?? "")
        }
    }

    @ViewBuilder
    private func feedRow(_ feed: Feed) -> some View {
        let label = FeedRowView(
            feed: feed,
            unreadCount: appState.unreadCount(for: feed)
        )

        if usesSplitNavigation {
            Button {
                selectedFeedID = feed.id
            } label: {
                label
            }
            .buttonStyle(.plain)
            .listRowBackground(
                selectedFeedID == feed.id
                    ? StillPalette.selectedChipFill(colorScheme).opacity(0.35)
                    : Color.clear
            )
        } else {
            NavigationLink {
                FeedDetailView(feed: feed)
            } label: {
                label
            }
        }
    }

    private func deleteFeeds(at offsets: IndexSet) {
        for index in offsets {
            let feed = appState.feeds[index]
            Task { try? await appState.deleteFeed(feed) }
        }
    }

    private func loadDemoFeeds() {
        guard !isLoadingDemoFeeds else { return }
        isLoadingDemoFeeds = true
        Task { @MainActor in
            defer { isLoadingDemoFeeds = false }
            do {
                let result = try await appState.loadDemoFeeds(refreshAfter: true)
                var message = "Added \(result.imported) feed\(result.imported == 1 ? "" : "s")"
                if result.skipped > 0 {
                    message += ", skipped \(result.skipped) duplicate\(result.skipped == 1 ? "" : "s")"
                }
                message += "."
                demoFeedMessage = message
            } catch {
                demoFeedMessage = error.localizedDescription
            }
        }
    }
}

private struct FeedRowView: View {
    let feed: Feed
    let unreadCount: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(feed.title)
                    .foregroundStyle(StillPalette.primaryText(colorScheme))
                Text(feed.url.host ?? feed.url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(StillPalette.secondaryText(colorScheme))
            }
            Spacer()
            if unreadCount > 0 {
                UnreadBadge(count: unreadCount)
            }
        }
    }
}
