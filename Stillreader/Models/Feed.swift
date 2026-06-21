import Foundation

struct Feed: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    var title: String
    var url: URL
    var siteURL: URL?
    var tags: [String]
    var created: Date
    var notes: String
    var slug: String
    var filePath: String

    init(
        id: String = UUID().uuidString,
        title: String,
        url: URL,
        siteURL: URL? = nil,
        tags: [String] = [],
        created: Date = Date(),
        notes: String = "",
        slug: String,
        filePath: String? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.siteURL = siteURL
        self.tags = tags
        self.created = created
        self.notes = notes
        self.slug = slug
        self.filePath = filePath ?? StoragePath.feed(slug)
    }

    init(from document: MarkdownDocument) throws {
        guard let urlString = document.frontmatter["url"] as? String,
              let url = URL(string: urlString)
        else {
            throw MarkdownParseError.missingRequiredField("url")
        }

        id = document.frontmatter["id"] as? String ?? UUID().uuidString
        title = document.frontmatter["title"] as? String ?? url.host ?? "Untitled"
        self.url = url

        if let site = document.frontmatter["site_url"] as? String {
            siteURL = URL(string: site)
        } else {
            siteURL = nil
        }

        tags = document.frontmatter["tags"] as? [String] ?? []

        if let createdString = document.frontmatter["created"] as? String {
            created = MarkdownDates.parse(createdString) ?? Date()
        } else {
            created = Date()
        }

        notes = document.body.trimmingCharacters(in: .whitespacesAndNewlines)
        slug = StoragePath.slugFromPath(document.path)
        filePath = document.path
    }
}
