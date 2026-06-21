import XCTest
@testable import Stillreader

final class StatePrunerTests: XCTestCase {
    func testReadLaterNeverPruned() {
        let old = Date(timeIntervalSince1970: 0)
        let state = FeedState(
            feedID: "f1",
            items: [
                StateItem(id: "a", status: .readLater, taggedAt: old),
            ],
            slug: "test"
        )

        let pruned = StatePruner.prune(state, now: Date())
        XCTAssertEqual(pruned.items.count, 1)
        XCTAssertEqual(pruned.items[0].status, .readLater)
    }

    func testOldReadEntriesPruned() {
        let old = Date(timeIntervalSince1970: 0)
        let recent = Date()
        let state = FeedState(
            feedID: "f1",
            items: [
                StateItem(id: "old", status: .read, readAt: old),
                StateItem(id: "new", status: .read, readAt: recent),
            ],
            slug: "test"
        )

        let pruned = StatePruner.prune(state, retentionDays: 90, now: recent)
        XCTAssertEqual(pruned.items.map(\.id), ["new"])
    }

    func testMaxReadEntriesEnforced() {
        let now = Date()
        let items = (0..<600).map { index in
            StateItem(
                id: "item-\(index)",
                status: .read,
                readAt: now.addingTimeInterval(TimeInterval(-index))
            )
        }
        let state = FeedState(feedID: "f1", items: items, slug: "test")

        let pruned = StatePruner.prune(state, maxReadEntries: 500, now: now)
        XCTAssertEqual(pruned.items.count, 500)
        XCTAssertTrue(pruned.items.contains { $0.id == "item-0" })
        XCTAssertFalse(pruned.items.contains { $0.id == "item-599" })
    }
}
