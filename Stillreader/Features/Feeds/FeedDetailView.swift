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
                    Task {
                        try? await appState.updateFeed(draft)
                    }
                }
            }

            Section("Articles") {
                ForEach(feedArticles) { article in
                    NavigationLink {
                        ReaderView(article: article, feed: feed)
                    } label: {
                        Text(article.title)
                    }
                }
            }
        }
        .navigationTitle(feed.title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Refresh") {
                    Task {
                        isRefreshing = true
                        await appState.refreshAll()
                        isRefreshing = false
                    }
                }
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
