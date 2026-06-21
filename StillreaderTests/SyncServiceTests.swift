import XCTest
@testable import Stillreader

final class SyncServiceTests: XCTestCase {
    @MainActor
    func testImportExternalFeedAssignsID() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let storage = LocalStorageAdapter(rootURL: tmp)
        let sync = SyncService(storage: storage)

        let external = """
        ---
        title: "External Feed"
        url: "https://example.com/rss.xml"
        ---
        """
        let path = StoragePath.feed("external-feed")
        try await storage.write(path: path, content: external)
        try await sync.sync()

        XCTAssertEqual(sync.feeds.count, 1)
        XCTAssertFalse(sync.feeds[0].id.isEmpty)
        XCTAssertEqual(sync.feeds[0].title, "External Feed")

        let normalized = try await storage.read(path: path)
        XCTAssertTrue(normalized.contains("id:"))
    }

    @MainActor
    func testAddFeedAndMarkRead() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let storage = LocalStorageAdapter(rootURL: tmp)
        let sync = SyncService(storage: storage)

        let feed = Feed(title: "Test", url: URL(string: "https://example.com/rss")!, slug: "test")
        try await sync.addFeed(feed)

        var state = FeedState(feedID: feed.id, slug: feed.slug)
        state.items.append(StateItem(id: "article-1", status: .read, readAt: Date()))
        try await sync.saveState(state)

        let stateContent = try await storage.read(path: StoragePath.feedState("test"))
        XCTAssertTrue(stateContent.contains("article-1"))
    }
}
