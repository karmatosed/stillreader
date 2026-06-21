import XCTest
@testable import Stillreader

final class MarkdownParserTests: XCTestCase {
    func testParseFeedRoundTrip() throws {
        let fixture = try loadFixture("sample-feed.md")
        let doc = try MarkdownParser.parse(content: fixture, path: "feeds/test-feed.md")
        let feed = try Feed(from: doc)

        XCTAssertEqual(feed.id, "feed_test")
        XCTAssertEqual(feed.title, "Test Feed")
        XCTAssertEqual(feed.url.absoluteString, "https://example.com/feed.xml")
        XCTAssertEqual(feed.tags, ["swift", "ios"])
        XCTAssertEqual(feed.notes, "My notes here.")
        XCTAssertEqual(feed.slug, "test-feed")

        let serialized = try MarkdownParser.serialize(feed: feed, slug: "test-feed")
        let reparsed = try Feed(from: MarkdownParser.parse(content: serialized, path: "feeds/test-feed.md"))
        XCTAssertEqual(reparsed.id, feed.id)
        XCTAssertEqual(reparsed.title, feed.title)
        XCTAssertEqual(reparsed.url, feed.url)
        XCTAssertEqual(reparsed.tags, feed.tags)
        XCTAssertEqual(reparsed.notes, feed.notes)
    }

    func testParseLinkRoundTrip() throws {
        let fixture = try loadFixture("sample-link.md")
        let doc = try MarkdownParser.parse(content: fixture, path: "links/2026-06-20-test-article.md")
        let link = try SavedLink(from: doc)

        XCTAssertEqual(link.id, "link_test")
        XCTAssertEqual(link.title, "Test Article")
        XCTAssertEqual(link.url.absoluteString, "https://example.com/article")
        XCTAssertEqual(link.tags, ["design"])
        XCTAssertFalse(link.isRead)
        XCTAssertEqual(link.notes, "Why I saved this.")

        let serialized = try MarkdownParser.serialize(link: link, slug: link.slug)
        let reparsed = try SavedLink(from: MarkdownParser.parse(content: serialized, path: link.filePath))
        XCTAssertEqual(reparsed.id, link.id)
        XCTAssertEqual(reparsed.title, link.title)
        XCTAssertEqual(reparsed.url, link.url)
        XCTAssertEqual(reparsed.isRead, link.isRead)
    }

    func testParseFeedStateRoundTrip() throws {
        let fixture = try loadFixture("sample-state.md")
        let doc = try MarkdownParser.parse(content: fixture, path: "state/test-feed.md")
        let state = try FeedState(from: doc)

        XCTAssertEqual(state.feedID, "feed_test")
        XCTAssertEqual(state.items.count, 2)
        XCTAssertEqual(state.items[0].status, .read)
        XCTAssertEqual(state.items[0].tags, ["inspiration"])
        XCTAssertEqual(state.items[1].status, .readLater)
        XCTAssertEqual(state.items[1].tags, ["todo"])

        let serialized = try MarkdownParser.serialize(state: state, slug: "test-feed")
        let reparsed = try FeedState(from: MarkdownParser.parse(content: serialized, path: "state/test-feed.md"))
        XCTAssertEqual(reparsed.feedID, state.feedID)
        XCTAssertEqual(reparsed.items, state.items)
    }

    func testMissingURLThrows() {
        let content = """
        ---
        title: "No URL"
        ---
        """

        XCTAssertThrowsError(try Feed(from: MarkdownParser.parse(content: content, path: "feeds/bad.md"))) { error in
            XCTAssertEqual(error as? MarkdownParseError, .missingRequiredField("url"))
        }
    }

    private func loadFixture(_ name: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
            .appendingPathComponent(name)
        return try String(contentsOf: url, encoding: .utf8)
    }
}
