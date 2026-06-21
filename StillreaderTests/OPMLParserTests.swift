import XCTest
@testable import Stillreader

final class OPMLParserTests: XCTestCase {
    func testParseOPMLFeeds() throws {
        let opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="1.0">
          <body>
            <outline type="rss" text="Example" title="Example" xmlUrl="https://example.com/rss.xml"/>
          </body>
        </opml>
        """

        let feeds = try OPMLParser.parse(opml)
        XCTAssertEqual(feeds.count, 1)
        XCTAssertEqual(feeds[0].title, "Example")
        XCTAssertEqual(feeds[0].url.absoluteString, "https://example.com/rss.xml")
    }
}
