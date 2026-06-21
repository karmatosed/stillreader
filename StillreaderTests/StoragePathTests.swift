import XCTest
@testable import Stillreader

final class StoragePathTests: XCTestCase {
    func testShardFromSlug() {
        XCTAssertEqual(StoragePath.shard(for: "smashing-magazine"), "s")
        XCTAssertEqual(StoragePath.shard(for: "123-feed"), "1")
        XCTAssertEqual(StoragePath.shard(for: ""), "_")
        XCTAssertEqual(StoragePath.shard(for: "---"), "_")
    }

    func testShardedFeedPath() {
        XCTAssertEqual(
            StoragePath.feed("smashing-magazine"),
            "feeds/s/smashing-magazine.md"
        )
    }

    func testShardedStatePath() {
        XCTAssertEqual(
            StoragePath.feedState("daring-fireball"),
            "state/d/daring-fireball.md"
        )
    }

    func testShardedLinkPath() {
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 20
        let date = Calendar(identifier: .gregorian).date(from: components)!

        XCTAssertEqual(
            StoragePath.link(filename: "2026-06-20-article", saved: date),
            "links/2026/06/2026-06-20-article.md"
        )
    }

    func testSlugFromPathIgnoresShardDirectories() {
        XCTAssertEqual(
            StoragePath.slugFromPath("feeds/s/smashing-magazine.md"),
            "smashing-magazine"
        )
        XCTAssertEqual(
            StoragePath.slugFromPath("links/2026/06/2026-06-20-article.md"),
            "2026-06-20-article"
        )
    }

    func testLegacyFlatFeedPathStillParsesSlug() {
        XCTAssertEqual(
            StoragePath.slugFromPath("feeds/legacy-feed.md"),
            "legacy-feed"
        )
    }
}
