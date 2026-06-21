import XCTest
@testable import Stillreader

final class StillreaderTests: XCTestCase {
    @MainActor
    func testAppStateBootstrap() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let storage = LocalStorageAdapter(rootURL: tmp)
        let cache = try ArticleCache.inMemory()
        let state = AppState(storage: storage, cache: cache)

        XCTAssertTrue(state.isReady)
        await state.bootstrap()
        XCTAssertTrue(state.isReady)
    }

    func testSeedFeedsEntries() throws {
        let entries = try SeedFeeds.entries()
        XCTAssertEqual(entries.count, 4)
    }

    @MainActor
    func testLoadDemoFeedsImportsFourFeeds() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let storage = LocalStorageAdapter(rootURL: tmp)
        let cache = try ArticleCache.inMemory()
        let state = AppState(storage: storage, cache: cache)

        let result = try await state.loadDemoFeeds(refreshAfter: false)
        XCTAssertEqual(result.imported, 4)
        XCTAssertEqual(state.feeds.count, 4)
    }

    @MainActor
    func testRefreshFetchesArticlesFromNetwork() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let storage = LocalStorageAdapter(rootURL: tmp)
        let cache = try ArticleCache.inMemory()
        let state = AppState(storage: storage, cache: cache)

        _ = try await state.loadDemoFeeds(refreshAfter: false)
        XCTAssertEqual(state.feeds.count, 4)

        await state.refreshAll()
        XCTAssertFalse(state.articles.isEmpty, "Expected articles after refresh")
    }

    @MainActor
    func testPrepareOnFirstAppearLoadsFeedsAndArticles() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let storage = LocalStorageAdapter(rootURL: tmp)
        let cache = try ArticleCache.inMemory()
        let state = AppState(storage: storage, cache: cache)

        await state.loadLibrary()
        _ = try await state.loadDemoFeeds(refreshAfter: false)
        XCTAssertEqual(state.feeds.count, 4)

        await state.fetchArticlesIfNeeded()
        XCTAssertFalse(state.articles.isEmpty, "Expected articles after fetchArticlesIfNeeded")
        XCTAssertFalse(state.inboxItems.isEmpty, "Expected inbox items after fetch")
    }
}
