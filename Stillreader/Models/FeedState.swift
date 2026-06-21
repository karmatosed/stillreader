import Foundation

struct FeedState: Equatable, Sendable {
    let feedID: String
    var updated: Date
    var items: [StateItem]
    var slug: String
    var filePath: String

    init(
        feedID: String,
        updated: Date = Date(),
        items: [StateItem] = [],
        slug: String,
        filePath: String? = nil
    ) {
        self.feedID = feedID
        self.updated = updated
        self.items = items
        self.slug = slug
        self.filePath = filePath ?? StoragePath.feedState(slug)
    }

    init(from document: MarkdownDocument) throws {
        guard let feedID = document.frontmatter["feed_id"] as? String else {
            throw MarkdownParseError.missingRequiredField("feed_id")
        }

        self.feedID = feedID

        if let updatedString = document.frontmatter["updated"] as? String {
            updated = MarkdownDates.parse(updatedString) ?? Date()
        } else {
            updated = Date()
        }

        if let rawItems = document.frontmatter["items"] as? [Any] {
            items = rawItems.compactMap { item in
                guard let dict = item as? [String: Any] else { return nil }
                return StateItem(yaml: dict)
            }
        } else {
            items = []
        }

        slug = StoragePath.slugFromPath(document.path)
        filePath = document.path
    }
}
