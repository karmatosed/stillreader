import Foundation

struct ArticleRoute: Hashable, Sendable {
    let articleID: String
    let feedID: String
}

struct LinkRoute: Hashable, Sendable {
    let linkID: String
}

enum InboxDetailSelection: Hashable, Sendable {
    case article(articleID: String, feedID: String)
    case readLater(itemID: String, feedID: String, title: String, url: URL)
    case link(linkID: String)
}
