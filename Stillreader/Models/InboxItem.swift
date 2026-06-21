import Foundation

enum InboxItem: Identifiable, Equatable, Sendable {
    case article(CachedArticle, feed: Feed)
    case readLater(itemID: String, title: String, url: URL, feed: Feed, tags: [String] = [], taggedAt: Date? = nil)
    case savedLink(SavedLink)

    var id: String {
        switch self {
        case let .article(article, _):
            return "article:\(article.id)"
        case let .readLater(itemID, _, _, _, _, _):
            return "later:\(itemID)"
        case let .savedLink(link):
            return "link:\(link.id)"
        }
    }
}
