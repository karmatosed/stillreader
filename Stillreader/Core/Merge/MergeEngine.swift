import Foundation

enum MergeEngine {
    static func unreadArticles(
        articles: [CachedArticle],
        feed: Feed,
        state: FeedState
    ) -> [CachedArticle] {
        let excluded = Set(
            state.items
                .filter { $0.status == .read || $0.status == .readLater }
                .map(\.id)
        )
        return articles.filter { !excluded.contains($0.id) }
    }

    static func readLaterItems(
        articles: [CachedArticle],
        feed: Feed,
        state: FeedState
    ) -> [ReadLaterItem] {
        state.items
            .filter { $0.status == .readLater }
            .map { item in
                if let cached = articles.first(where: { $0.id == item.id }) {
                    return ReadLaterItem(
                        itemID: item.id,
                        title: cached.title,
                        url: cached.url,
                        taggedAt: item.taggedAt,
                        tags: item.tags
                    )
                }
                return ReadLaterItem(
                    itemID: item.id,
                    title: item.id,
                    url: URL(string: "about:blank")!,
                    taggedAt: item.taggedAt,
                    tags: item.tags
                )
            }
    }

    static func unreadLinks(links: [SavedLink]) -> [SavedLink] {
        links.filter { !$0.isRead }
    }

    static func inbox(
        feeds: [Feed],
        articles: [CachedArticle],
        states: [String: FeedState],
        links: [SavedLink]
    ) -> [InboxItem] {
        var items: [InboxItem] = []

        for feed in feeds {
            let state = states[feed.id] ?? FeedState(feedID: feed.id, slug: feed.slug)
            let feedArticles = articles.filter { $0.feedID == feed.id }
            for article in unreadArticles(articles: feedArticles, feed: feed, state: state) {
                items.append(.article(article, feed: feed))
            }
        }

        for link in unreadLinks(links: links) {
            items.append(.savedLink(link))
        }

        return items.sorted { $0.sortDate > $1.sortDate }
    }

    static func readLaterInbox(
        feeds: [Feed],
        articles: [CachedArticle],
        states: [String: FeedState]
    ) -> [InboxItem] {
        var items: [InboxItem] = []

        for feed in feeds {
            let state = states[feed.id] ?? FeedState(feedID: feed.id, slug: feed.slug)
            let feedArticles = articles.filter { $0.feedID == feed.id }
            for later in readLaterItems(articles: feedArticles, feed: feed, state: state) {
                items.append(
                    .readLater(
                        itemID: later.itemID,
                        title: later.title,
                        url: later.url,
                        feed: feed,
                        tags: later.tags,
                        taggedAt: later.taggedAt
                    )
                )
            }
        }

        return items.sorted { $0.sortDate > $1.sortDate }
    }

    static func inboxSections(
        groupedByFeed: Bool,
        feeds: [Feed],
        articles: [CachedArticle],
        states: [String: FeedState],
        links: [SavedLink]
    ) -> [InboxSection] {
        var sections: [InboxSection] = []

        let later = readLaterInbox(feeds: feeds, articles: articles, states: states)
        if !later.isEmpty {
            sections.append(InboxSection(id: "read-later", title: "Read later", items: later))
        }

        if groupedByFeed {
            for feed in feeds.sorted(by: { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }) {
                let state = states[feed.id] ?? FeedState(feedID: feed.id, slug: feed.slug)
                let feedArticles = articles.filter { $0.feedID == feed.id }
                let items = unreadArticles(articles: feedArticles, feed: feed, state: state)
                    .sorted { $0.published > $1.published }
                    .map { InboxItem.article($0, feed: feed) }
                guard !items.isEmpty else { continue }
                sections.append(InboxSection(id: feed.id, title: feed.title, items: items))
            }
        } else {
            let flat = inbox(feeds: feeds, articles: articles, states: states, links: [])
            if !flat.isEmpty {
                sections.append(InboxSection(id: "inbox", title: nil, items: flat))
            }
        }

        let linkItems = unreadLinks(links: links).map { InboxItem.savedLink($0) }
        if !linkItems.isEmpty {
            sections.append(InboxSection(id: "links", title: "Saved links", items: linkItems))
        }

        return sections
    }
}

struct ReadLaterItem: Equatable, Sendable {
    let itemID: String
    let title: String
    let url: URL
    var taggedAt: Date?
    var tags: [String] = []
}

struct InboxSection: Identifiable, Equatable, Sendable {
    let id: String
    let title: String?
    let items: [InboxItem]
}

private extension InboxItem {
    var sortDate: Date {
        switch self {
        case let .article(article, _):
            return article.published
        case let .readLater(_, _, _, _, _, taggedAt):
            return taggedAt ?? Date.distantPast
        case let .savedLink(link):
            return link.saved
        }
    }
}
