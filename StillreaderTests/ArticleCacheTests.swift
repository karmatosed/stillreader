import XCTest
@testable import Stillreader

final class ArticleCacheTests: XCTestCase {
    func testUpsertAndSearch() throws {
        let cache = try ArticleCache.inMemory()
        let article = CachedArticle(
            id: "1",
            feedID: "feed1",
            title: "Swift Concurrency",
            url: URL(string: "https://example.com/1")!,
            excerpt: "Structured concurrency patterns",
            published: Date()
        )

        try cache.upsert([article])
        let results = try cache.search(query: "Concurrency")
        XCTAssertEqual(results.map(\.id), ["1"])
    }

    func testPruneRemovesOldArticles() throws {
        let cache = try ArticleCache.inMemory()
        let old = CachedArticle(
            id: "old",
            feedID: "feed1",
            title: "Old",
            url: URL(string: "https://example.com/old")!,
            excerpt: "",
            published: Date(timeIntervalSince1970: 0),
            fetchedAt: Date(timeIntervalSince1970: 0)
        )
        try cache.upsert([old])
        try cache.prune(olderThan: Date(timeIntervalSince1970: 1000))
        XCTAssertTrue(try cache.allArticles().isEmpty)
    }
}
