import Foundation

enum SeedFeeds {
    static let autoLoadKey = "didAutoLoadDemoFeeds"

    /// Set to `false` when demo feeds should no longer load on first launch.
    static let autoLoadOnLaunch = true

    static func entries() throws -> [OPMLFeed] {
        if let url = Bundle.main.url(forResource: "seed-feeds", withExtension: "opml"),
           let data = try? Data(contentsOf: url),
           let parsed = try? OPMLParser.parse(data),
           !parsed.isEmpty {
            return parsed
        }
        return fallbackEntries
    }

    /// Bundled OPML fallback so demo feeds always work even if the resource is missing.
    private static let fallbackEntries: [OPMLFeed] = [
        OPMLFeed(
            title: "The Verge",
            url: URL(string: "https://www.theverge.com/rss/index.xml")!
        ),
        OPMLFeed(
            title: "Hacker News",
            url: URL(string: "https://hnrss.org/frontpage")!
        ),
        OPMLFeed(
            title: "BBC Technology",
            url: URL(string: "https://feeds.bbci.co.uk/news/technology/rss.xml")!
        ),
        OPMLFeed(
            title: "Daring Fireball",
            url: URL(string: "https://daringfireball.net/feeds/main")!
        ),
    ]
}

enum SeedFeedsError: LocalizedError {
    case missingResource

    var errorDescription: String? {
        switch self {
        case .missingResource:
            return "Demo feeds file is missing from the app bundle."
        }
    }
}
