import XCTest
@testable import Stillreader

final class RichTextFormatterTests: XCTestCase {
    func testPlainTextFromHTMLStripsTags() {
        let html = "<p>Hello <strong>world</strong>.</p>"
        XCTAssertEqual(RichTextFormatter.plainTextFromHTML(html), "Hello world.")
    }

    func testLooksLikeHTML() {
        XCTAssertTrue(RichTextFormatter.looksLikeHTML("<p>Test</p>"))
        XCTAssertFalse(RichTextFormatter.looksLikeHTML("Plain text only"))
    }

    func testAttributedFromMarkdown() {
        let attributed = RichTextFormatter.attributed(from: "Hello **world**")
        XCTAssertNotNil(attributed)
        XCTAssertTrue(String(attributed!.characters).contains("world"))
    }

    func testPreviewTextFromHTML() {
        let preview = RichTextFormatter.previewText(from: "<p>First paragraph</p><p>Second</p>")
        XCTAssertTrue(preview.contains("First paragraph"))
        XCTAssertFalse(preview.contains("<p>"))
    }
}
