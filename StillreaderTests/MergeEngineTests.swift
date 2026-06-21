import XCTest
@testable import Stillreader

final class MergeEngineTests: XCTestCase {
    private let feed = Feed(
        id: "feed_1",
        title: "F",
        url: URL(string: "https://x.com/rss")!,
        slug: "f",
        filePath: "feeds/f.md"
    )

    private var articles: [CachedArticle] {
        [
            CachedArticle(
                id: "a1",
                feedID: feed.id,
                title: "One",
                url: URL(string: "https://x.com/1")!,
                excerpt: "",
                published: Date(timeIntervalSince1970: 100)
            ),
            CachedArticle(
                id: "a2",
                feedID: feed.id,
                title: "Two",
                url: URL(string: "https://x.com/2")!,
                excerpt: "",
                published: Date(timeIntervalSince1970: 200)
            ),
        ]
    }

    func testUnreadExcludesReadItems() {
        let state = FeedState(
            feedID: feed.id,
            items: [
                StateItem(id: "a1", status: .read, readAt: Date()),
            ],
            slug: feed.slug
        )

        let unread = MergeEngine.unreadArticles(articles: articles, feed: feed, state: state)
        XCTAssertEqual(unread.map(\.id), ["a2"])
    }

    func testReadLaterSurvivesWithoutCache() {
        let state = FeedState(
            feedID: feed.id,
            items: [
                StateItem(id: "gone", status: .readLater, taggedAt: Date()),
            ],
            slug: feed.slug
        )

        let later = MergeEngine.readLaterItems(articles: [], feed: feed, state: state)
        XCTAssertEqual(later.count, 1)
        XCTAssertEqual(later[0].itemID, "gone")
    }

    func testUnreadExcludesReadLaterItems() {
        let state = FeedState(
            feedID: feed.id,
            items: [
                StateItem(id: "a1", status: .readLater, taggedAt: Date()),
            ],
            slug: feed.slug
        )

        let unread = MergeEngine.unreadArticles(articles: articles, feed: feed, state: state)
        XCTAssertEqual(unread.map(\.id), ["a2"])
    }

    func testInboxSectionsIncludeReadLater() {
        let state = FeedState(
            feedID: feed.id,
            items: [
                StateItem(id: "a1", status: .readLater, taggedAt: Date(), tags: ["todo"]),
            ],
            slug: feed.slug
        )
        let sections = MergeEngine.inboxSections(
            groupedByFeed: false,
            feeds: [feed],
            articles: articles,
            states: [feed.id: state],
            links: []
        )
        XCTAssertTrue(sections.contains { $0.id == "read-later" })
        XCTAssertEqual(sections.first { $0.id == "read-later" }?.items.count, 1)
    }

    func testInboxIncludesUnreadArticlesAndLinks() {
        let link = SavedLink(
            id: "link_1",
            url: URL(string: "https://example.com/saved")!,
            title: "Saved",
            slug: "saved",
            filePath: "links/saved.md"
        )
        let states = [feed.id: FeedState(feedID: feed.id, slug: feed.slug)]

        let items = MergeEngine.inbox(
            feeds: [feed],
            articles: articles,
            states: states,
            links: [link]
        )

        XCTAssertEqual(items.count, 3)
        XCTAssertTrue(items.contains { if case .savedLink = $0 { true } else { false } })
    }

    func testUnreadLinksFiltersRead() {
        let unread = SavedLink(
            url: URL(string: "https://example.com/1")!,
            title: "Unread",
            slug: "unread"
        )
        var read = SavedLink(
            url: URL(string: "https://example.com/2")!,
            title: "Read",
            slug: "read"
        )
        read.isRead = true

        let result = MergeEngine.unreadLinks(links: [unread, read])
        XCTAssertEqual(result.map(\.id), [unread.id])
    }
}
