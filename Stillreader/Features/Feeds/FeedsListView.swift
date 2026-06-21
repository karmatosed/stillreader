import SwiftUI

struct FeedsListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingAddFeed = false
    @State private var showingImport = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(appState.feeds) { feed in
                    NavigationLink {
                        FeedDetailView(feed: feed)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(feed.title)
                                Text(feed.url.host ?? feed.url.absoluteString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            let unread = appState.unreadCount(for: feed)
                            if unread > 0 {
                                Text("\(unread)")
                                    .font(.caption.bold())
                                    .padding(6)
                                    .background(Circle().fill(Color.accentColor.opacity(0.2)))
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let feed = appState.feeds[index]
                        Task { try? await appState.deleteFeed(feed) }
                    }
                }
            }
            .navigationTitle("Feeds")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Add feed") { showingAddFeed = true }
                        Button("Import OPML") { showingImport = true }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFeed) {
                AddFeedView()
            }
            .sheet(isPresented: $showingImport) {
                OPMLImportView()
            }
            .overlay {
                if appState.feeds.isEmpty {
                    ContentUnavailableView(
                        "No feeds",
                        systemImage: "dot.radiowaves.up.forward",
                        description: Text("Add a feed or import OPML to get started.")
                    )
                }
            }
        }
    }
}
