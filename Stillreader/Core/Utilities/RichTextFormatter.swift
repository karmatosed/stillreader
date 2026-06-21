import Foundation

enum RichTextFormatter {
    static func attributed(from content: String) -> AttributedString? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard !looksLikeHTML(trimmed) else { return nil }

        if let markdown = try? AttributedString(
            markdown: trimmed,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return markdown
        }
        return AttributedString(trimmed)
    }

    /// Plain-text excerpt for lists. Must stay lightweight — no WebKit/HTML layout on the main thread.
    static func previewText(from content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        if looksLikeHTML(trimmed) {
            return stripTags(from: trimmed)
        }
        if let markdown = try? AttributedString(
            markdown: trimmed,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return String(markdown.characters).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
    }

    static func looksLikeHTML(_ content: String) -> Bool {
        content.range(
            of: #"<\/?[a-zA-Z][^>]*>"#,
            options: .regularExpression
        ) != nil
    }

    static func plainTextFromHTML(_ html: String) -> String {
        if let attributed = attributedFromHTML(html) {
            return String(attributed.characters)
                .replacingOccurrences(of: "\u{FFFC}", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return stripTags(from: html)
    }

    private static func attributedFromHTML(_ html: String) -> AttributedString? {
        let document = html.contains("<html") ? html : """
        <!DOCTYPE html>
        <html><head><meta charset="utf-8"></head><body>\(html)</body></html>
        """
        guard let data = document.data(using: .utf8) else { return nil }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]
        guard let nsAttributed = try? NSAttributedString(
            data: data,
            options: options,
            documentAttributes: nil
        ) else {
            return nil
        }

        var attributed = AttributedString(nsAttributed)
        stripHardcodedColors(from: &attributed)
        return attributed
    }

    private static func stripHardcodedColors(from attributed: inout AttributedString) {
        for run in attributed.runs {
            if run.foregroundColor != nil {
                attributed[run.range].foregroundColor = nil
            }
            if run.backgroundColor != nil {
                attributed[run.range].backgroundColor = nil
            }
        }
    }

    private static func stripTags(from html: String) -> String {
        let withoutTags = html.replacingOccurrences(
            of: "<[^>]+>",
            with: " ",
            options: .regularExpression
        )
        return decodeHTMLEntities(
            withoutTags
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    /// Fast entity decoding for list previews — avoids NSAttributedString HTML parsing during layout.
    private static func decodeHTMLEntities(_ text: String) -> String {
        var result = text
        let named: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&apos;", "'"),
            ("&#39;", "'"),
            ("&nbsp;", " "),
            ("&hellip;", "…"),
            ("&mdash;", "—"),
            ("&ndash;", "–"),
        ]
        for (entity, character) in named {
            result = result.replacingOccurrences(of: entity, with: character)
        }
        return result
    }
}
