import Foundation

enum MergeEngine {
    static func unreadArticles(
        articles: [CachedArticle],
        feed: Feed,
        state: FeedState
    ) -> [CachedArticle] {
        let readIDs = Set(state.items.filter { $0.status == .read }.map(\.id))
        return articles.filter { !readIDs.contains($0.id) }
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
                        url: cached.url
                    )
                }
                return ReadLaterItem(
                    itemID: item.id,
                    title: item.id,
                    url: URL(string: "about:blank")!
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
}

struct ReadLaterItem: Equatable, Sendable {
    let itemID: String
    let title: String
    let url: URL
}

private extension InboxItem {
    var sortDate: Date {
        switch self {
        case let .article(article, _):
            return article.published
        case .readLater:
            return .distantPast
        case let .savedLink(link):
            return link.saved
        }
    }
}
