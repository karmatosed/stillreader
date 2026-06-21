import Foundation
import GRDB

final class ArticleCache {
    private let dbQueue: DatabaseQueue

    init(databaseURL: URL) throws {
        dbQueue = try DatabaseQueue(path: databaseURL.path)
        try migrator.migrate(dbQueue)
    }

    private init(dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue
        try migrator.migrate(dbQueue)
    }

    static func inMemory() throws -> ArticleCache {
        try ArticleCache(dbQueue: DatabaseQueue())
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: "cached_articles") { table in
                table.column("id", .text).primaryKey()
                table.column("feed_id", .text).notNull().indexed()
                table.column("title", .text).notNull()
                table.column("url", .text).notNull()
                table.column("excerpt", .text).notNull()
                table.column("published", .datetime).notNull()
                table.column("fetched_at", .datetime).notNull()
            }
            try db.create(virtualTable: "articles_fts", using: FTS5()) { table in
                table.column("id")
                table.column("title")
                table.column("excerpt")
            }
        }
        return migrator
    }

    func upsert(_ articles: [CachedArticle]) throws {
        try dbQueue.write { db in
            for article in articles {
                try db.execute(
                    sql: """
                    INSERT INTO cached_articles (id, feed_id, title, url, excerpt, published, fetched_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(id) DO UPDATE SET
                        feed_id = excluded.feed_id,
                        title = excluded.title,
                        url = excluded.url,
                        excerpt = excluded.excerpt,
                        published = excluded.published,
                        fetched_at = excluded.fetched_at
                    """,
                    arguments: [
                        article.id,
                        article.feedID,
                        article.title,
                        article.url.absoluteString,
                        article.excerpt,
                        article.published,
                        article.fetchedAt,
                    ]
                )
                try db.execute(sql: "DELETE FROM articles_fts WHERE id = ?", arguments: [article.id])
                try db.execute(
                    sql: "INSERT INTO articles_fts (id, title, excerpt) VALUES (?, ?, ?)",
                    arguments: [article.id, article.title, article.excerpt]
                )
            }
        }
    }

    func articles(forFeedID feedID: String) throws -> [CachedArticle] {
        try dbQueue.read { db in
            try CachedArticleRow
                .filter(Column("feed_id") == feedID)
                .order(Column("published").desc)
                .fetchAll(db)
                .map { $0.toModel() }
        }
    }

    func allArticles() throws -> [CachedArticle] {
        try dbQueue.read { db in
            try CachedArticleRow
                .order(Column("published").desc)
                .fetchAll(db)
                .map { $0.toModel() }
        }
    }

    func prune(olderThan date: Date) throws {
        try dbQueue.write { db in
            let ids = try String.fetchAll(
                db,
                sql: "SELECT id FROM cached_articles WHERE fetched_at < ?",
                arguments: [date]
            )
            try db.execute(
                sql: "DELETE FROM cached_articles WHERE fetched_at < ?",
                arguments: [date]
            )
            for id in ids {
                try db.execute(sql: "DELETE FROM articles_fts WHERE id = ?", arguments: [id])
            }
        }
    }

    func search(query: String) throws -> [CachedArticle] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return try allArticles() }

        return try dbQueue.read { db in
            let ids = try String.fetchAll(
                db,
                sql: """
                SELECT id FROM articles_fts
                WHERE articles_fts MATCH ?
                """,
                arguments: [trimmed]
            )
            guard !ids.isEmpty else { return [] }
            let idSet = Set(ids)
            return try CachedArticleRow
                .fetchAll(db)
                .filter { idSet.contains($0.id) }
                .map { $0.toModel() }
        }
    }

    func delete(forFeedID feedID: String) throws {
        try dbQueue.write { db in
            let ids = try String.fetchAll(
                db,
                sql: "SELECT id FROM cached_articles WHERE feed_id = ?",
                arguments: [feedID]
            )
            try db.execute(sql: "DELETE FROM cached_articles WHERE feed_id = ?", arguments: [feedID])
            for id in ids {
                try db.execute(sql: "DELETE FROM articles_fts WHERE id = ?", arguments: [id])
            }
        }
    }
}

private struct CachedArticleRow: Codable, FetchableRecord, TableRecord {
    static let databaseTableName = "cached_articles"

    var id: String
    var feed_id: String
    var title: String
    var url: String
    var excerpt: String
    var published: Date
    var fetched_at: Date

    func toModel() -> CachedArticle {
        CachedArticle(
            id: id,
            feedID: feed_id,
            title: title,
            url: URL(string: url) ?? URL(string: "about:blank")!,
            excerpt: excerpt,
            published: published,
            fetchedAt: fetched_at
        )
    }
}

enum SearchIndex {
    static func search(cache: ArticleCache, query: String) throws -> [CachedArticle] {
        try cache.search(query: query)
    }
}
