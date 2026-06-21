import Foundation

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
        struct Outcome {
            let feedID: String
            let articles: [CachedArticle]?
            let error: String?
        }

        let outcomes = await withTaskGroup(of: Outcome.self, returning: [Outcome].self) { group in
            for feed in feeds {
                group.addTask {
                    do {
                        let data = try await self.fetcher.fetch(url: feed.url)
                        let parsed = try FeedKitParser.parse(data: data, feedID: feed.id)
                        return Outcome(feedID: feed.id, articles: parsed, error: nil)
                    } catch {
                        return Outcome(feedID: feed.id, articles: nil, error: error.localizedDescription)
                    }
                }
            }

            var collected: [Outcome] = []
            for await outcome in group {
                collected.append(outcome)
            }
            return collected
        }

        for outcome in outcomes {
            if let articles = outcome.articles {
                try? cache.upsert(articles)
                try? await metaStore.recordSuccess(feedID: outcome.feedID, count: articles.count)
            } else if let error = outcome.error {
                try? await metaStore.recordError(feedID: outcome.feedID, error: error)
            }
        }

        let cutoff = Date().addingTimeInterval(-30 * 24 * 3600)
        try? cache.prune(olderThan: cutoff)
    }
}
