import Foundation

@MainActor
final class RefreshService {
    private let fetcher: FeedFetcher
    private let cache: ArticleCache
    private let metaStore: AppMetaStore

    init(fetcher: FeedFetcher, cache: ArticleCache, metaStore: AppMetaStore) {
        self.fetcher = fetcher
        self.cache = cache
        self.metaStore = metaStore
    }

    func refresh(feed: Feed) async throws -> Int {
        let data = try await fetcher.fetch(url: feed.url)
        let parsed = try FeedKitParser.parse(data: data, feedID: feed.id)
        try cache.upsert(parsed)
        try await metaStore.recordSuccess(feedID: feed.id, count: parsed.count)
        return parsed.count
    }

    func refreshAll(feeds: [Feed]) async {
        for feed in feeds {
            do {
                _ = try await refresh(feed: feed)
            } catch {
                try? await metaStore.recordError(feedID: feed.id, error: error.localizedDescription)
            }
        }
        let cutoff = Date().addingTimeInterval(-30 * 24 * 3600)
        try? cache.prune(olderThan: cutoff)
    }
}
