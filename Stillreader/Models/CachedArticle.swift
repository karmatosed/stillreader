import Foundation

struct CachedArticle: Identifiable, Equatable, Sendable {
    let id: String
    let feedID: String
    var title: String
    var url: URL
    var excerpt: String
    var published: Date
    var fetchedAt: Date

    init(
        id: String,
        feedID: String,
        title: String,
        url: URL,
        excerpt: String,
        published: Date,
        fetchedAt: Date = Date()
    ) {
        self.id = id
        self.feedID = feedID
        self.title = title
        self.url = url
        self.excerpt = excerpt
        self.published = published
        self.fetchedAt = fetchedAt
    }
}
