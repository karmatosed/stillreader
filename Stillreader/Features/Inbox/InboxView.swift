import SwiftUI

struct InboxView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("inboxGroupedByFeed") private var inboxGroupedByFeed = false

    @Binding private var selectedDetail: InboxDetailSelection?
    private let usesSplitNavigation: Bool

    @State private var isRefreshing = false
    @State private var tagTarget: TagTarget?

    private struct TagTarget: Identifiable {
        let id: String
        let feed: Feed
        let article: CachedArticle
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
                inboxList
            } else {
                NavigationStack {
                    inboxList
                }
            }
        }
    }

    private var inboxList: some View {
        List {
            if appState.isUsingLocalFallback {
                CalmOfflineBanner(message: "Using local storage — iCloud unavailable on this device.")
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }

            if !appState.feeds.isEmpty {
                CalmStatusBar(
                    lastRefresh: appState.lastRefresh,
                    isRefreshing: isRefreshing || appState.isRefreshingAll
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            if appState.inboxSections.isEmpty {
                emptyInboxContent
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(appState.inboxSections) { section in
                    Section {
                        ForEach(section.items) { item in
                            inboxRow(item)
                        }
                    } header: {
                        if let title = section.title {
                            Text(title)
                                .foregroundStyle(StillPalette.secondaryText(colorScheme))
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(StillPalette.screenBackground(colorScheme))
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(usesSplitNavigation ? .inline : .large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await refresh() }
                } label: {
                    if isRefreshing || appState.isRefreshingAll {
                        ProgressView()
                            .tint(StillPalette.accent(colorScheme))
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(StillPalette.primaryText(colorScheme))
                    }
                }
                .disabled(isRefreshing || appState.isRefreshingAll || appState.feeds.isEmpty)
                .accessibilityIdentifier("inboxRefreshButton")
            }
        }
        .refreshable { await refresh() }
        .onChange(of: inboxGroupedByFeed) { _, _ in
            appState.reloadInboxLayout()
        }
        .sheet(item: $tagTarget) { target in
            TagArticleSheet(
                feed: target.feed,
                articleID: target.article.id,
                articleTitle: target.article.title,
                initialTags: appState.tags(for: target.feed, articleID: target.article.id)
            ) { tags in
                try? await appState.setArticleTags(
                    feed: target.feed,
                    articleID: target.article.id,
                    tags: tags
                )
            }
        }
    }

    private var emptyInboxContent: some View {
        ContentUnavailableView {
            Label("Inbox empty", systemImage: "tray")
                .foregroundStyle(StillPalette.primaryText(colorScheme))
        } description: {
            if appState.feeds.isEmpty {
                if let launchMessage = appState.launchMessage {
                    Text(launchMessage)
                } else if !appState.syncIssues.isEmpty {
                    Text(appState.syncIssues.first ?? "Could not load feeds.")
                } else {
                    Text("Add feeds to start reading.")
                }
            } else if appState.articles.isEmpty {
                if appState.isRefreshingAll {
                    Text("Fetching articles…")
                } else if !appState.feedErrors.isEmpty {
                    Text("Could not fetch articles. Check your network connection.")
                } else {
                    Text("No articles yet.")
                }
            } else {
                Text("You're all caught up.")
            }
        } actions: {
            if appState.feeds.isEmpty {
                if appState.launchMessage != nil {
                    ProgressView()
                        .tint(StillPalette.accent(colorScheme))
                } else {
                    Button("Load demo feeds") {
                        Task { try? await appState.loadDemoFeeds(refreshAfter: true) }
                    }
                    .buttonStyle(.calmProminent)
                }
            } else if appState.articles.isEmpty, !appState.isRefreshingAll {
                Button("Fetch articles") {
                    Task { await appState.fetchArticlesIfNeeded() }
                }
                .buttonStyle(.calmProminent)
            }
        }
    }

    @ViewBuilder
    private func inboxRow(_ item: InboxItem) -> some View {
        switch item {
        case let .article(article, feed):
            articleRow(article: article, feed: feed)
        case let .readLater(itemID, title, url, feed, tags, _):
            readLaterRow(itemID: itemID, title: title, url: url, feed: feed, tags: tags)
        case let .savedLink(link):
            savedLinkRow(link)
        }
    }

    @ViewBuilder
    private func articleRow(article: CachedArticle, feed: Feed) -> some View {
        let detail = InboxDetailSelection.article(articleID: article.id, feedID: feed.id)
        let label = articleLabel(title: article.title, subtitle: feed.title, excerpt: article.excerpt)

        Group {
            if usesSplitNavigation {
                Button {
                    selectedDetail = detail
                } label: {
                    label
                }
                .buttonStyle(.plain)
                .listRowBackground(rowBackground(isSelected: selectedDetail == detail))
            } else {
                NavigationLink {
                    ReaderView(article: article, feed: feed)
                } label: {
                    label
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Read") {
                Task { try? await appState.markRead(feed: feed, articleID: article.id) }
            }
            .tint(StillPalette.prominentFill(colorScheme))
        }
        .swipeActions(edge: .leading) {
            Button("Later") {
                Task { try? await appState.markReadLater(feed: feed, articleID: article.id) }
            }
            .tint(StillPalette.subtleFill(colorScheme))
            Button("Tag") {
                tagTarget = TagTarget(id: article.id, feed: feed, article: article)
            }
            .tint(StillPalette.selectedChipFill(colorScheme))
        }
        .contextMenu {
            Button("Mark read") {
                Task { try? await appState.markRead(feed: feed, articleID: article.id) }
            }
            Button("Read later") {
                Task { try? await appState.markReadLater(feed: feed, articleID: article.id) }
            }
            Button("Tag…") {
                tagTarget = TagTarget(id: article.id, feed: feed, article: article)
            }
        }
    }

    @ViewBuilder
    private func readLaterRow(itemID: String, title: String, url: URL, feed: Feed, tags: [String]) -> some View {
        let detail = InboxDetailSelection.readLater(
            itemID: itemID,
            feedID: feed.id,
            title: title,
            url: url
        )
        let label = readLaterLabel(title: title, feed: feed, tags: tags)

        Group {
            if usesSplitNavigation {
                Button {
                    selectedDetail = detail
                } label: {
                    label
                }
                .buttonStyle(.plain)
                .listRowBackground(rowBackground(isSelected: selectedDetail == detail))
            } else if let article = appState.articles.first(where: { $0.id == itemID && $0.feedID == feed.id }) {
                NavigationLink {
                    ReaderView(article: article, feed: feed)
                } label: {
                    label
                }
            } else {
                NavigationLink {
                    ReadLaterFallbackView(title: title, url: url, feed: feed)
                } label: {
                    label
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Read") {
                Task { try? await appState.markRead(feed: feed, articleID: itemID) }
            }
        }
    }

    @ViewBuilder
    private func savedLinkRow(_ link: SavedLink) -> some View {
        let detail = InboxDetailSelection.link(linkID: link.id)
        let label = VStack(alignment: .leading, spacing: 4) {
            Text(link.title)
                .foregroundStyle(StillPalette.primaryText(colorScheme))
            Text("Saved link")
                .font(.caption)
                .foregroundStyle(StillPalette.secondaryText(colorScheme))
        }
        .padding(.vertical, 4)

        Group {
            if usesSplitNavigation {
                Button {
                    selectedDetail = detail
                } label: {
                    label
                }
                .buttonStyle(.plain)
                .listRowBackground(rowBackground(isSelected: selectedDetail == detail))
            } else {
                NavigationLink {
                    LinkReaderView(link: link)
                } label: {
                    label
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Read") {
                Task { try? await appState.markLinkRead(link) }
            }
        }
    }

    private func rowBackground(isSelected: Bool) -> some View {
        Group {
            if isSelected {
                StillPalette.selectedChipFill(colorScheme).opacity(0.35)
            } else {
                Color.clear
            }
        }
    }

    private func articleLabel(title: String, subtitle: String, excerpt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(StillPalette.primaryText(colorScheme))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(StillPalette.secondaryText(colorScheme))
            if !excerpt.isEmpty {
                Text(RichTextFormatter.previewText(from: excerpt))
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(StillPalette.tertiaryText(colorScheme))
            }
        }
        .padding(.vertical, 4)
    }

    private func readLaterLabel(title: String, feed: Feed, tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(StillPalette.primaryText(colorScheme))
            Text(feed.title)
                .font(.caption)
                .foregroundStyle(StillPalette.secondaryText(colorScheme))
            if !tags.isEmpty {
                Text(tags.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(StillPalette.tertiaryText(colorScheme))
            }
        }
        .padding(.vertical, 4)
    }

    private func refresh() async {
        isRefreshing = true
        await appState.refreshAll()
        isRefreshing = false
    }
}
