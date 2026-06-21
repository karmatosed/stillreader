import Foundation
import Yams

enum MarkdownParser {
    static func parse(content: String, path: String) throws -> MarkdownDocument {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("---") else {
            throw MarkdownParseError.missingFrontmatter
        }

        var lines = trimmed.components(separatedBy: .newlines)
        lines.removeFirst()
        var yamlLines: [String] = []
        while let line = lines.first, line != "---" {
            yamlLines.append(lines.removeFirst())
        }
        guard lines.first == "---" else {
            throw MarkdownParseError.missingFrontmatter
        }
        lines.removeFirst()
        let body = lines.joined(separator: "\n")

        let yaml = yamlLines.joined(separator: "\n")
        guard let node = try Yams.load(yaml: yaml) as? [String: Any] else {
            throw MarkdownParseError.invalidYAML(path)
        }
        return MarkdownDocument(path: path, frontmatter: node, body: body)
    }

    static func serialize(feed: Feed, slug _: String) throws -> String {
        var frontmatter: [String: Any] = [
            "id": feed.id,
            "title": feed.title,
            "url": feed.url.absoluteString,
            "tags": feed.tags,
            "created": MarkdownDates.format(feed.created),
        ]
        if let siteURL = feed.siteURL {
            frontmatter["site_url"] = siteURL.absoluteString
        }
        return try serializeDocument(frontmatter: frontmatter, body: feed.notes)
    }

    static func serialize(link: SavedLink, slug _: String) throws -> String {
        var frontmatter: [String: Any] = [
            "id": link.id,
            "url": link.url.absoluteString,
            "title": link.title,
            "tags": link.tags,
            "saved": MarkdownDates.format(link.saved),
            "read": link.isRead,
        ]
        if let readAt = link.readAt {
            frontmatter["read_at"] = MarkdownDates.format(readAt)
        }
        return try serializeDocument(frontmatter: frontmatter, body: link.notes)
    }

    static func serialize(state: FeedState, slug _: String) throws -> String {
        let frontmatter: [String: Any] = [
            "feed_id": state.feedID,
            "updated": MarkdownDates.format(state.updated),
            "items": state.items.map(\.yamlDictionary),
        ]
        return try serializeDocument(frontmatter: frontmatter, body: "")
    }

    private static func serializeDocument(frontmatter: [String: Any], body: String) throws -> String {
        let yaml = try Yams.dump(object: frontmatter).trimmingCharacters(in: .whitespacesAndNewlines)
        var content = "---\n\(yaml)\n---\n"
        if !body.isEmpty {
            content += body
            if !body.hasSuffix("\n") {
                content += "\n"
            }
        }
        return content
    }
}
