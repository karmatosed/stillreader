import Foundation
import Yams

struct AppMeta: Equatable, Sendable {
    var schemaVersion: Int
    var lastRefresh: Date?
    var feedsRefreshed: [FeedRefreshMeta]

    static let empty = AppMeta(schemaVersion: 1, lastRefresh: nil, feedsRefreshed: [])
}

struct FeedRefreshMeta: Equatable, Sendable {
    let id: String
    var refreshedAt: Date?
    var itemCount: Int
    var error: String?
}

final class AppMetaStore {
    private let storage: StorageProvider
    private(set) var meta = AppMeta.empty

    init(storage: StorageProvider) {
        self.storage = storage
    }

    func load() async throws {
        guard try await storage.exists(path: StoragePath.meta) else {
            meta = .empty
            return
        }
        let content = try await storage.read(path: StoragePath.meta)
        meta = try parse(content: content)
    }

    func recordSuccess(feedID: String, count: Int) async throws {
        let now = Date()
        meta.lastRefresh = now
        upsertFeedMeta(id: feedID, refreshedAt: now, itemCount: count, error: nil)
        try await save()
    }

    func recordError(feedID: String, error: String) async throws {
        upsertFeedMeta(id: feedID, refreshedAt: nil, itemCount: 0, error: error)
        try await save()
    }

    private func upsertFeedMeta(id: String, refreshedAt: Date?, itemCount: Int, error: String?) {
        if let index = meta.feedsRefreshed.firstIndex(where: { $0.id == id }) {
            meta.feedsRefreshed[index].refreshedAt = refreshedAt
            meta.feedsRefreshed[index].itemCount = itemCount
            meta.feedsRefreshed[index].error = error
        } else {
            meta.feedsRefreshed.append(
                FeedRefreshMeta(id: id, refreshedAt: refreshedAt, itemCount: itemCount, error: error)
            )
        }
    }

    private func save() async throws {
        let object: [String: Any] = [
            "schema_version": meta.schemaVersion,
            "last_refresh": meta.lastRefresh.map { MarkdownDates.format($0) } as Any,
            "feeds_refreshed": meta.feedsRefreshed.map { entry -> [String: Any] in
                var dict: [String: Any] = [
                    "id": entry.id,
                    "item_count": entry.itemCount,
                    "error": entry.error as Any,
                ]
                if let refreshedAt = entry.refreshedAt {
                    dict["refreshed_at"] = MarkdownDates.format(refreshedAt)
                }
                return dict
            },
        ]
        let yaml = try Yams.dump(object: object).trimmingCharacters(in: .whitespacesAndNewlines)
        let content = "---\n\(yaml)\n---\n"
        try await storage.write(path: StoragePath.meta, content: content)
    }

    private func parse(content: String) throws -> AppMeta {
        let doc = try MarkdownParser.parse(content: content, path: StoragePath.meta)
        let version = doc.frontmatter["schema_version"] as? Int ?? 1
        let lastRefresh = (doc.frontmatter["last_refresh"] as? String).flatMap { MarkdownDates.parse($0) }

        let feeds: [FeedRefreshMeta]
        if let raw = doc.frontmatter["feeds_refreshed"] as? [Any] {
            feeds = raw.compactMap { item -> FeedRefreshMeta? in
                guard let dict = item as? [String: Any], let id = dict["id"] as? String else { return nil }
                let refreshedAt = (dict["refreshed_at"] as? String).flatMap { MarkdownDates.parse($0) }
                let count = dict["item_count"] as? Int ?? 0
                let error = dict["error"] as? String
                return FeedRefreshMeta(id: id, refreshedAt: refreshedAt, itemCount: count, error: error)
            }
        } else {
            feeds = []
        }

        return AppMeta(schemaVersion: version, lastRefresh: lastRefresh, feedsRefreshed: feeds)
    }
}
