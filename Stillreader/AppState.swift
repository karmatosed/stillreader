import Combine
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var isReady = true
    @Published var syncIssues: [String] = []
    @Published var feeds: [Feed] = []
    @Published var links: [SavedLink] = []
    @Published var states: [String: FeedState] = [:]
    @Published var articles: [CachedArticle] = []
    @Published var lastRefresh: Date?
    @Published var feedErrors: [String: String] = [:]
    @Published var iCloudAvailable = false
    @Published var storageLocation: StorageLocation = .localFallback
    @Published var inboxItems: [InboxItem] = []
    @Published var inboxSections: [InboxSection] = []
    @Published var isRefreshingAll = false
    @Published var refreshingFeedID: String?
    @Published var launchMessage: String?
    @Published var isUsingLocalFallback = false

    private var didBootstrap = false

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
        if ProcessInfo.processInfo.arguments.contains("-FreshInstall") {
            Self.clearLocalData()
        } else {
            Self.migrateStorageIfNeeded()
        }

        let resolvedStorage: StorageProvider
        if let storage {
            resolvedStorage = storage
        } else {
            resolvedStorage = ICloudStorageAdapter()
        }
        self.storage = resolvedStorage
        storageLocation = .localFallback
        iCloudAvailable = false
        isUsingLocalFallback = true

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
        guard !didBootstrap else { return }
        didBootstrap = true
    }

    /// Called on launch — loads library and demo feeds if needed.
    func prepareOnFirstAppear() async {
        guard !didBootstrap else { return }

        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }

        if ProcessInfo.processInfo.arguments.contains("-SkipAutoLoadDemoFeeds") {
            didBootstrap = true
            await loadLibrary()
            return
        }

        didBootstrap = true
        launchMessage = "Loading library…"
        await runDemoFeedBootstrap()

        if !feeds.isEmpty, articles.isEmpty {
            launchMessage = "Fetching articles…"
            await fetchArticlesIfNeeded()
        }

        launchMessage = nil
    }

    func resetAllData() async {
        didBootstrap = false
        launchMessage = nil
        syncIssues = []
        feedErrors = [:]
        Self.clearLocalData()
        feeds = []
        links = []
        states = [:]
        articles = []
        inboxItems = []
        await prepareOnFirstAppear()
    }

    /// Fetches RSS articles for all subscribed feeds.
    func fetchArticlesIfNeeded() async {
        guard !feeds.isEmpty else { return }
        guard !isRefreshingAll else { return }

        await refreshAll()
        publishFetchErrorsIfNeeded()
    }

    private func publishFetchErrorsIfNeeded() {
        guard articles.isEmpty, !feedErrors.isEmpty else { return }
        syncIssues = feedErrors.map { _, error in error }
    }

    private func runDemoFeedBootstrap() async {
        await loadLibrary()

        guard feeds.isEmpty, SeedFeeds.autoLoadOnLaunch else { return }

        launchMessage = "Importing demo feeds…"
        do {
            let result = try await loadDemoFeeds(refreshAfter: false)
            if result.imported == 0, result.skipped == 0 {
                syncIssues = ["No demo feeds were imported."]
            }
        } catch {
            syncIssues = [error.localizedDescription]
        }
    }

    /// Re-sync when returning to foreground (picks up share extension + external files).
    func syncOnForeground() async {
        await loadLibrary()
    }

    func refreshFeed(_ feed: Feed) async {
        guard refreshingFeedID == nil else { return }
        refreshingFeedID = feed.id
        defer { refreshingFeedID = nil }

        do {
            _ = try await refreshService.refresh(feed: feed)
            reloadArticles()
            lastRefresh = metaStore.meta.lastRefresh
            feedErrors = Dictionary(
                uniqueKeysWithValues: metaStore.meta.feedsRefreshed.compactMap { entry in
                    guard let error = entry.error else { return nil }
                    return (entry.id, error)
                }
            )
            rebuildInbox()
        } catch {
            feedErrors[feed.id] = error.localizedDescription
        }
    }

    func setArticleTags(feed: Feed, articleID: String, tags: [String]) async throws {
        var state = states[feed.id] ?? FeedState(feedID: feed.id, slug: feed.slug)
        if let index = state.items.firstIndex(where: { $0.id == articleID }) {
            state.items[index].tags = tags
            if state.items[index].status == .read {
                state.items[index].taggedAt = Date()
            }
        } else {
            state.items.append(
                StateItem(id: articleID, status: .readLater, taggedAt: Date(), tags: tags)
            )
        }
        try await syncService.saveState(state)
        applySyncSnapshot()
        rebuildInbox()
    }

    func tags(for feed: Feed, articleID: String) -> [String] {
        let state = states[feed.id] ?? FeedState(feedID: feed.id, slug: feed.slug)
        return state.items.first(where: { $0.id == articleID })?.tags ?? []
    }

    func reloadInboxLayout() {
        rebuildInbox()
    }

    /// Loads feeds/links from disk. Call from Settings or after adding feeds.
    func loadLibrary() async {
        do {
            try await syncService.sync()
            try await metaStore.load()
            applySyncSnapshot()
            updateStorageStatus()
            reloadArticles()
            rebuildInbox()
        } catch {
            syncIssues = [error.localizedDescription]
        }
    }

    func sync() async throws {
        try await syncService.sync()
        applySyncSnapshot()
        rebuildInbox()
    }

    func refreshAll() async {
        guard !isRefreshingAll else { return }
        isRefreshingAll = true
        defer { isRefreshingAll = false }

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

    func loadDemoFeeds(refreshAfter: Bool = true) async throws -> (imported: Int, skipped: Int) {
        let result = try await importOPMLFeeds(try SeedFeeds.entries())
        if refreshAfter {
            await fetchArticlesIfNeeded()
        }
        return result
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
            applySyncSnapshot()
        }

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
        let cache = articleCache
        articles = (try? cache.allArticles()) ?? []
    }

    private func rebuildInbox() {
        let grouped = UserDefaults.standard.bool(forKey: "inboxGroupedByFeed")
        inboxSections = MergeEngine.inboxSections(
            groupedByFeed: grouped,
            feeds: feeds,
            articles: articles,
            states: states,
            links: links
        )
        inboxItems = MergeEngine.inbox(
            feeds: feeds,
            articles: articles,
            states: states,
            links: links
        )
    }

    private func updateStorageStatus() {
        guard let cloud = storage as? ICloudStorageAdapter else { return }
        iCloudAvailable = cloud.isCloudAvailable
        storageLocation = cloud.storageLocation
        isUsingLocalFallback = cloud.storageLocation == .localFallback
    }

    private static func clearLocalData() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let stillreaderRoot = appSupport.appendingPathComponent("Stillreader", isDirectory: true)
        let cacheURL = appSupport.appendingPathComponent("cache.sqlite")
        try? fileManager.removeItem(at: stillreaderRoot)
        try? fileManager.removeItem(at: cacheURL)
        try? fileManager.removeItem(at: cacheURL.appendingPathExtension("shm"))
        try? fileManager.removeItem(at: cacheURL.appendingPathExtension("wal"))
    }

    /// Wipes corrupt data from earlier builds once per storage generation bump.
    private static func migrateStorageIfNeeded() {
        let key = "stillreaderStorageGeneration"
        let current = 5
        let stored = UserDefaults.standard.integer(forKey: key)
        guard stored < current else { return }
        clearLocalData()
        UserDefaults.standard.set(current, forKey: key)
    }
}
