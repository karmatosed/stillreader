import Combine
import Foundation
import SwiftUI

enum AppSection: Hashable {
    case inbox
    case feeds
    case links
    case search
    case settings
}

@MainActor
final class AppState: ObservableObject {
    @Published var isReady = false
    @Published var syncIssues: [String] = []
    @Published var feeds: [Feed] = []
    @Published var links: [SavedLink] = []
    @Published var states: [String: FeedState] = [:]
    @Published var articles: [CachedArticle] = []
    @Published var lastRefresh: Date?
    @Published var feedErrors: [String: String] = [:]
    @Published var iCloudAvailable = false
    @Published var inboxItems: [InboxItem] = []

    let storage: StorageProvider
    private let syncService: SyncService
    private let refreshService: RefreshService
    private let articleCache: ArticleCache
    private let metaStore: AppMetaStore

    init(
        storage: StorageProvider? = nil,
        cache: ArticleCache? = nil,
        fetcher: FeedFetcher = DirectFeedFetcher()
    ) {
        let resolvedStorage = storage ?? ICloudStorageAdapter()
        if let cloud = resolvedStorage as? ICloudStorageAdapter {
            iCloudAvailable = cloud.isCloudAvailable
        }

        self.storage = resolvedStorage
        self.syncService = SyncService(storage: resolvedStorage)

        let resolvedCache: ArticleCache
        if let cache {
            resolvedCache = cache
        } else {
            let cacheURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("cache.sqlite")
            do {
                resolvedCache = try ArticleCache(databaseURL: cacheURL)
            } catch {
                do {
                    resolvedCache = try ArticleCache.inMemory()
                } catch {
                    fatalError("Unable to initialize article cache: \(error)")
                }
            }
        }
        self.articleCache = resolvedCache
        self.metaStore = AppMetaStore(storage: resolvedStorage)
        self.refreshService = RefreshService(
            fetcher: fetcher,
            cache: resolvedCache,
            metaStore: metaStore
        )
    }

    func bootstrap() async {
        do {
            try await syncService.sync()
            try await metaStore.load()
            applySyncSnapshot()
            reloadArticles()
            rebuildInbox()
            isReady = true
        } catch {
            syncIssues = [error.localizedDescription]
            isReady = true
        }
    }

    func sync() async throws {
        try await syncService.sync()
        applySyncSnapshot()
        rebuildInbox()
    }

    func refreshAll() async {
        await refreshService.refreshAll(feeds: feeds)
        reloadArticles()
        lastRefresh = metaStore.meta.lastRefresh
        feedErrors = Dictionary(
            uniqueKeysWithValues: metaStore.meta.feedsRefreshed.compactMap { entry in
                guard let error = entry.error else { return nil }
                return (entry.id, error)
            }
        )
        rebuildInbox()
    }

    func addFeed(url: URL, title: String? = nil) async throws {
        let slug = Slugifier.uniqueSlug(
            from: title ?? url.host ?? "feed",
            existing: Set(feeds.map(\.slug))
        )
        let feed = Feed(
            title: title ?? url.host ?? "New feed",
            url: url,
            slug: slug
        )
        try await syncService.addFeed(feed)
        applySyncSnapshot()
        rebuildInbox()
    }

    func importOPMLFeeds(_ entries: [OPMLFeed]) async throws -> (imported: Int, skipped: Int) {
        var imported = 0
        var skipped = 0
        let existing = syncService.existingFeedURLs()

        for entry in entries {
            if existing.contains(entry.url.absoluteString) {
                skipped += 1
                continue
            }
            let slug = Slugifier.uniqueSlug(from: entry.title, existing: Set(feeds.map(\.slug)))
            let feed = Feed(title: entry.title, url: entry.url, slug: slug)
            try await syncService.addFeed(feed)
            imported += 1
        }

        applySyncSnapshot()
        rebuildInbox()
        return (imported, skipped)
    }

    func deleteFeed(_ feed: Feed) async throws {
        try await syncService.deleteFeed(feed)
        try articleCache.delete(forFeedID: feed.id)
        applySyncSnapshot()
        reloadArticles()
        rebuildInbox()
    }

    func updateFeed(_ feed: Feed) async throws {
        try await syncService.updateFeed(feed)
        applySyncSnapshot()
        rebuildInbox()
    }

    func saveLink(url: URL, title: String) async throws {
        let slug = Slugifier.slug(from: title)
        let link = SavedLink(url: url, title: title, slug: slug)
        try await syncService.addLink(link)
        applySyncSnapshot()
        rebuildInbox()
    }

    func markLinkRead(_ link: SavedLink) async throws {
        var updated = link
        updated.isRead = true
        updated.readAt = Date()
        try await syncService.updateLink(updated)
        applySyncSnapshot()
        rebuildInbox()
    }

    func markRead(feed: Feed, articleID: String) async throws {
        var state = states[feed.id] ?? FeedState(feedID: feed.id, slug: feed.slug)
        state.items.removeAll { $0.id == articleID }
        state.items.append(StateItem(id: articleID, status: .read, readAt: Date()))
        try await syncService.saveState(state)
        applySyncSnapshot()
        rebuildInbox()
    }

    func markReadLater(feed: Feed, articleID: String) async throws {
        var state = states[feed.id] ?? FeedState(feedID: feed.id, slug: feed.slug)
        state.items.removeAll { $0.id == articleID }
        state.items.append(StateItem(id: articleID, status: .readLater, taggedAt: Date()))
        try await syncService.saveState(state)
        applySyncSnapshot()
        rebuildInbox()
    }

    func markAllRead(feed: Feed, articleIDs: [String]) async throws {
        var state = states[feed.id] ?? FeedState(feedID: feed.id, slug: feed.slug)
        let now = Date()
        for articleID in articleIDs {
            state.items.removeAll { $0.id == articleID }
            state.items.append(StateItem(id: articleID, status: .read, readAt: now))
        }
        try await syncService.saveState(state)
        applySyncSnapshot()
        rebuildInbox()
    }

    func searchArticles(query: String) throws -> [CachedArticle] {
        try SearchIndex.search(cache: articleCache, query: query)
    }

    func unreadCount(for feed: Feed) -> Int {
        let state = states[feed.id] ?? FeedState(feedID: feed.id, slug: feed.slug)
        let feedArticles = articles.filter { $0.feedID == feed.id }
        return MergeEngine.unreadArticles(articles: feedArticles, feed: feed, state: state).count
    }

    func allTags() -> [String] {
        Array(
            Set(
                feeds.flatMap(\.tags)
                    + links.flatMap(\.tags)
                    + states.values.flatMap(\.items).flatMap(\.tags)
            )
        ).sorted()
    }

    private func applySyncSnapshot() {
        feeds = syncService.feeds
        links = syncService.links
        states = syncService.states
        syncIssues = syncService.syncIssues
    }

    private func reloadArticles() {
        articles = (try? articleCache.allArticles()) ?? []
    }

    private func rebuildInbox() {
        inboxItems = MergeEngine.inbox(
            feeds: feeds,
            articles: articles,
            states: states,
            links: links
        )
    }
}
