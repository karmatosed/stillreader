import SwiftUI

struct FeedDetailView: View {
    @EnvironmentObject private var appState: AppState
    let feed: Feed

    @State private var draft: Feed
    @State private var isRefreshing = false

    init(feed: Feed) {
        self.feed = feed
        _draft = State(initialValue: feed)
    }

    private var feedArticles: [CachedArticle] {
        appState.articles.filter { $0.feedID == feed.id }
    }

    var body: some View {
        List {
            Section("Details") {
                TextField("Title", text: $draft.title)
                TextField("Tags (comma separated)", text: Binding(
                    get: { draft.tags.joined(separator: ", ") },
                    set: { draft.tags = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                ))
                TextEditor(text: $draft.notes)
                    .frame(minHeight: 80)
                Button("Save") {
                    Task { try? await appState.updateFeed(draft) }
                }
            }

            Section("Articles") {
                if feedArticles.isEmpty {
                    Text("No articles yet. Tap Refresh to fetch this feed.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(feedArticles) { article in
                        NavigationLink {
                            ReaderView(article: article, feed: feed)
                        } label: {
                            Text(article.title)
                        }
                    }
                }
            }
        }
        .navigationTitle(feed.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    Task {
                        isRefreshing = true
                        await appState.refreshFeed(feed)
                        isRefreshing = false
                    }
                } label: {
                    if isRefreshing || appState.refreshingFeedID == feed.id {
                        ProgressView()
                    } else {
                        Text("Refresh")
                    }
                }
                .disabled(isRefreshing || appState.refreshingFeedID == feed.id)

                Button("Mark all read") {
                    Task {
                        try? await appState.markAllRead(
                            feed: feed,
                            articleIDs: feedArticles.map(\.id)
                        )
                    }
                }
            }
        }
    }
}
