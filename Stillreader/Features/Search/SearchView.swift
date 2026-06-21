import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var appState: AppState

    @State private var query = ""
    @State private var selectedTag: String?
    @State private var filterUnreadOnly = false
    @State private var results: [CachedArticle] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(appState.allTags(), id: \.self) { tag in
                            Button(tag) {
                                selectedTag = selectedTag == tag ? nil : tag
                                search()
                            }
                            .buttonStyle(.bordered)
                            .tint(selectedTag == tag ? .accentColor : .gray)
                        }
                    }
                    .padding(.horizontal)
                }

                Toggle("Unread only", isOn: $filterUnreadOnly)
                    .padding()
                    .onChange(of: filterUnreadOnly) { _, _ in search() }

                List(filteredResults) { article in
                    if let feed = appState.feeds.first(where: { $0.id == article.feedID }) {
                        NavigationLink {
                            ReaderView(article: article, feed: feed)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(article.title)
                                Text(feed.title).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query)
            .onChange(of: query) { _, _ in search() }
            .onAppear { search() }
        }
    }

    private var filteredResults: [CachedArticle] {
        var items = results
        if filterUnreadOnly {
            items = items.filter { article in
                guard let feed = appState.feeds.first(where: { $0.id == article.feedID }) else { return false }
                let state = appState.states[feed.id] ?? FeedState(feedID: feed.id, slug: feed.slug)
                return MergeEngine.unreadArticles(articles: [article], feed: feed, state: state).count == 1
            }
        }
        if let selectedTag {
            items = items.filter { article in
                guard let feed = appState.feeds.first(where: { $0.id == article.feedID }) else { return false }
                if feed.tags.contains(selectedTag) { return true }
                let state = appState.states[feed.id]
                return state?.items.first(where: { $0.id == article.id })?.tags.contains(selectedTag) ?? false
            }
        }
        return items
    }

    private func search() {
        results = (try? appState.searchArticles(query: query)) ?? []
    }
}
