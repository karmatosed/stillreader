import Foundation

enum LinkSaver {
    static func save(url: URL, title: String, storage: StorageProvider) async throws -> SavedLink {
        let slug = Slugifier.slug(from: title)
        let link = SavedLink(url: url, title: title, slug: slug)
        let content = try MarkdownParser.serialize(link: link, slug: slug)
        try await storage.ensureLayout()
        try await storage.write(path: link.filePath, content: content)
        return link
    }
}
