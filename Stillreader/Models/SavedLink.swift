import Foundation

struct SavedLink: Identifiable, Equatable, Sendable {
    let id: String
    var url: URL
    var title: String
    var tags: [String]
    var saved: Date
    var isRead: Bool
    var readAt: Date?
    var notes: String
    var slug: String
    var filePath: String

    init(
        id: String = UUID().uuidString,
        url: URL,
        title: String,
        tags: [String] = [],
        saved: Date = Date(),
        isRead: Bool = false,
        readAt: Date? = nil,
        notes: String = "",
        slug: String,
        filePath: String? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.tags = tags
        self.saved = saved
        self.isRead = isRead
        self.readAt = readAt
        self.notes = notes
        self.slug = slug
        if let filePath {
            self.filePath = filePath
        } else {
            let datePrefix = String(MarkdownDates.format(saved).prefix(10))
            let filename = StoragePath.linkFilename(datePrefix: datePrefix, slug: slug)
            self.filePath = StoragePath.link(filename: filename, saved: saved)
        }
    }

    init(from document: MarkdownDocument) throws {
        guard let urlString = document.frontmatter["url"] as? String,
              let url = URL(string: urlString)
        else {
            throw MarkdownParseError.missingRequiredField("url")
        }

        id = document.frontmatter["id"] as? String ?? UUID().uuidString
        self.url = url
        title = document.frontmatter["title"] as? String ?? url.host ?? "Saved link"
        tags = document.frontmatter["tags"] as? [String] ?? []

        if let savedString = document.frontmatter["saved"] as? String {
            saved = MarkdownDates.parse(savedString) ?? Date()
        } else {
            saved = Date()
        }

        isRead = document.frontmatter["read"] as? Bool ?? false

        if let readAtString = document.frontmatter["read_at"] as? String {
            readAt = MarkdownDates.parse(readAtString)
        } else {
            readAt = nil
        }

        notes = document.body.trimmingCharacters(in: .whitespacesAndNewlines)
        slug = StoragePath.slugFromPath(document.path)
        filePath = document.path
    }
}
