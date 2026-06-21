import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    @Binding private var selectedDetail: InboxDetailSelection?
    private let usesSplitNavigation: Bool

    @State private var query = ""
    @State private var selectedTag: String?
    @State private var filterUnreadOnly = false
    @State private var results: [CachedArticle] = []

    private var searchKey: String {
        "\(query)|\(filterUnreadOnly)|\(selectedTag ?? "")"
    }

    init() {
        _selectedDetail = .constant(nil)
        usesSplitNavigation = false
    }

    init(selectedDetail: Binding<InboxDetailSelection?>) {
        _selectedDetail = selectedDetail
        usesSplitNavigation = true
    }

    var body: some View {
        Group {
            if usesSplitNavigation {
                searchContent
            } else {
                NavigationStack {
                    searchContent
                }
            }
        }
    }

    private var searchContent: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(StillPalette.secondaryText(colorScheme))
                TextField("Search articles", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(StillPalette.primaryText(colorScheme))
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(StillPalette.elevatedBackground(colorScheme))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(appState.allTags(), id: \.self) { tag in
                        Button(tag) {
                            selectedTag = selectedTag == tag ? nil : tag
                        }
                        .buttonStyle(CalmChipButtonStyle(isSelected: selectedTag == tag))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Toggle("Unread only", isOn: $filterUnreadOnly)
                .padding(.horizontal)
                .tint(StillPalette.accent(colorScheme))

            List(filteredResults) { article in
                if let feed = appState.feeds.first(where: { $0.id == article.feedID }) {
                    resultRow(article: article, feed: feed)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .background(StillPalette.screenBackground(colorScheme))
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { search() }
        .task(id: searchKey) {
            guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                results = []
                return
            }
            search()
        }
    }

    @ViewBuilder
    private func resultRow(article: CachedArticle, feed: Feed) -> some View {
        let detail = InboxDetailSelection.article(articleID: article.id, feedID: feed.id)
        let label = VStack(alignment: .leading) {
            Text(article.title)
                .foregroundStyle(StillPalette.primaryText(colorScheme))
            Text(feed.title)
                .font(.caption)
                .foregroundStyle(StillPalette.secondaryText(colorScheme))
        }

        if usesSplitNavigation {
            Button {
                selectedDetail = detail
            } label: {
                label
            }
            .buttonStyle(.plain)
            .listRowBackground(
                selectedDetail == detail
                    ? StillPalette.selectedChipFill(colorScheme).opacity(0.35)
                    : Color.clear
            )
        } else {
            NavigationLink {
                ReaderView(article: article, feed: feed)
            } label: {
                label
            }
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
