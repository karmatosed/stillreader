import Foundation

enum StoragePath {
    static let feeds = "feeds"
    static let links = "links"
    static let state = "state"
    static let stillreaderMeta = ".stillreader"

    static let layoutDirectories = [feeds, links, state, stillreaderMeta]

    /// Read entries older than this are pruned from state files.
    static let stateReadRetentionDays = 90

    /// Maximum read entries kept per feed (most recent by read_at).
    static let stateMaxReadEntries = 500

    /// Read links older than this may be archived (future); read entries in state use stateReadRetentionDays.
    static let readLinkArchiveDays = 90

    /// First character of slug, lowercased; non-alphanumeric slugs use `_`.
    static func shard(for slug: String) -> String {
        guard let first = slug.first else { return "_" }
        if first.isLetter || first.isNumber {
            return String(first).lowercased()
        }
        return "_"
    }

    static func feed(_ slug: String) -> String {
        "\(feeds)/\(shard(for: slug))/\(slug).md"
    }

    static func feedState(_ slug: String) -> String {
        "\(state)/\(shard(for: slug))/\(slug).md"
    }

    static func link(filename: String, saved: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: saved)
        let month = String(format: "%02d", calendar.component(.month, from: saved))
        return "\(links)/\(year)/\(month)/\(filename).md"
    }

    static func linkFilename(datePrefix: String, slug: String) -> String {
        "\(datePrefix)-\(slug)"
    }

    /// Slug is always the filename without extension, regardless of shard depth.
    static func slugFromPath(_ path: String) -> String {
        URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    }
}
