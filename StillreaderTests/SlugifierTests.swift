import XCTest
@testable import Stillreader

final class SlugifierTests: XCTestCase {
    func testSlugifyTitle() {
        XCTAssertEqual(Slugifier.slug(from: "Smashing Magazine"), "smashing-magazine")
        XCTAssertEqual(Slugifier.slug(from: "Hello World!"), "hello-world")
    }

    func testSlugifyEmptyFallback() {
        XCTAssertEqual(Slugifier.slug(from: "---"), "untitled")
    }

    func testUniqueSlugAvoidsCollision() {
        let existing: Set<String> = ["smashing-magazine"]
        XCTAssertEqual(
            Slugifier.uniqueSlug(from: "Smashing Magazine", existing: existing),
            "smashing-magazine-2"
        )
    }

    func testUniqueSlugReturnsBaseWhenAvailable() {
        let existing: Set<String> = ["other-feed"]
        XCTAssertEqual(
            Slugifier.uniqueSlug(from: "Smashing Magazine", existing: existing),
            "smashing-magazine"
        )
    }
}
