import Foundation

@MainActor
final class SyncService {
    private let storage: StorageProvider
    private var lastWrittenHashes: [String: String] = [:]

    private(set) var feeds: [Feed] = []
    private(set) var links: [SavedLink] = []
    private(set) var states: [String: FeedState] = [:]
    private(set) var syncIssues: [String] = []

    init(storage: StorageProvider) {
        self.storage = storage
    }

    func sync() async throws {
        syncIssues = []
        try await storage.ensureLayout()
        try await reloadFeeds()
        try await reloadLinks()
        try await reloadStates()
    }

    func addFeed(_ feed: Feed) async throws {
        let content = try MarkdownParser.serialize(feed: feed, slug: feed.slug)
        try await write(path: feed.filePath, content: content)
        feeds.append(feed)
        feeds.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func updateFeed(_ feed: Feed) async throws {
        let content = try MarkdownParser.serialize(feed: feed, slug: feed.slug)
        try await write(path: feed.filePath, content: content)
        if let index = feeds.firstIndex(where: { $0.id == feed.id }) {
            feeds[index] = feed
        }
    }

    func deleteFeed(_ feed: Feed) async throws {
        try await storage.delete(path: feed.filePath)
        try await storage.delete(path: StoragePath.feedState(feed.slug))
        lastWrittenHashes.removeValue(forKey: feed.filePath)
        lastWrittenHashes.removeValue(forKey: StoragePath.feedState(feed.slug))
        feeds.removeAll { $0.id == feed.id }
        states.removeValue(forKey: feed.id)
    }

    func addLink(_ link: SavedLink) async throws {
        let content = try MarkdownParser.serialize(link: link, slug: link.slug)
        try await write(path: link.filePath, content: content)
        links.append(link)
        links.sort { $0.saved > $1.saved }
    }

    func updateLink(_ link: SavedLink) async throws {
        let content = try MarkdownParser.serialize(link: link, slug: link.slug)
        try await write(path: link.filePath, content: content)
        if let index = links.firstIndex(where: { $0.id == link.id }) {
            links[index] = link
        }
    }

    func saveState(_ state: FeedState) async throws {
        let pruned = StatePruner.prune(state)
        let content = try MarkdownParser.serialize(state: pruned, slug: pruned.slug)
        try await write(path: pruned.filePath, content: content)
        states[pruned.feedID] = pruned
    }

    func existingFeedURLs() -> Set<String> {
        Set(feeds.map { $0.url.absoluteString })
    }

    private func write(path: String, content: String) async throws {
        try await storage.write(path: path, content: content)
        lastWrittenHashes[path] = ContentHasher.hash(content)
    }

    private func reloadFeeds() async throws {
        let paths = try await storage.list(prefix: "\(StoragePath.feeds)/")
        var loaded: [Feed] = []

        for path in paths {
            let content = try await storage.read(path: path)
            let hash = ContentHasher.hash(content)

            if let previous = lastWrittenHashes[path], previous != hash {
                continue
            }

            do {
                var feed = try Feed(from: MarkdownParser.parse(content: content, path: path))

                if !content.contains("id:") {
                    feed = Feed(
                        id: UUID().uuidString,
                        title: feed.title,
                        url: feed.url,
                        siteURL: feed.siteURL,
                        tags: feed.tags,
                        created: feed.created,
                        notes: feed.notes,
                        slug: feed.slug,
                        filePath: path
                    )
                    let normalized = try MarkdownParser.serialize(feed: feed, slug: feed.slug)
                    try await write(path: path, content: normalized)
                }

                loaded.append(feed)
                lastWrittenHashes[path] = hash
            } catch {
                syncIssues.append("Could not parse feed \(path): \(error.localizedDescription)")
            }
        }

        feeds = loaded.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    private func reloadLinks() async throws {
        let paths = try await storage.list(prefix: "\(StoragePath.links)/")
        var loaded: [SavedLink] = []

        for path in paths {
            let content = try await storage.read(path: path)
            let hash = ContentHasher.hash(content)

            if let previous = lastWrittenHashes[path], previous != hash {
                continue
            }

            do {
                let link = try SavedLink(from: MarkdownParser.parse(content: content, path: path))
                loaded.append(link)
                lastWrittenHashes[path] = hash
            } catch {
                syncIssues.append("Could not parse link \(path): \(error.localizedDescription)")
            }
        }

        links = loaded.sorted { $0.saved > $1.saved }
    }

    private func reloadStates() async throws {
        let paths = try await storage.list(prefix: "\(StoragePath.state)/")
        var loaded: [String: FeedState] = [:]

        for path in paths {
            let content = try await storage.read(path: path)
            let hash = ContentHasher.hash(content)

            if let previous = lastWrittenHashes[path], previous != hash {
                if let existing = states.values.first(where: { $0.filePath == path }) {
                    loaded[existing.feedID] = existing
                }
                continue
            }

            do {
                let state = try FeedState(from: MarkdownParser.parse(content: content, path: path))
                loaded[state.feedID] = state
                lastWrittenHashes[path] = hash
            } catch {
                syncIssues.append("Could not parse state \(path): \(error.localizedDescription)")
            }
        }

        states = loaded
    }
}
