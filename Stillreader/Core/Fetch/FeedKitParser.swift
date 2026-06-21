import Foundation

enum FeedKitParser {
    static func parse(data: Data, feedID: String) throws -> [CachedArticle] {
        let parser = RSSParserDelegate(feedID: feedID)
        let xml = XMLParser(data: data)
        xml.delegate = parser
        guard xml.parse() else {
            throw FeedParseError.invalidFeed
        }
        return parser.articles
    }
}

enum FeedParseError: Error {
    case invalidFeed
}

private final class RSSParserDelegate: NSObject, XMLParserDelegate {
    let feedID: String
    var articles: [CachedArticle] = []

    private var inItem = false
    private var currentTitle = ""
    private var currentLink = ""
    private var currentGUID = ""
    private var currentDescription = ""
    private var currentEncoded = ""
    private var currentPubDate = ""
    private var currentElement = ""

    init(feedID: String) {
        self.feedID = feedID
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
        if elementName == "item" || elementName == "entry" {
            inItem = true
            resetCurrent()
        }
        if inItem, elementName == "link", let href = attributeDict["href"] {
            currentLink = href
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard inItem else { return }
        switch currentElement {
        case "title": currentTitle += string
        case "link": currentLink += string
        case "guid", "id": currentGUID += string
        case "description", "summary", "content":
            currentDescription += string
        case "encoded":
            currentEncoded += string
        case "pubDate", "published", "updated": currentPubDate += string
        default: break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "item" || elementName == "entry" {
            appendCurrent()
            inItem = false
        }
        currentElement = ""
    }

    private func resetCurrent() {
        currentTitle = ""
        currentLink = ""
        currentGUID = ""
        currentDescription = ""
        currentEncoded = ""
        currentPubDate = ""
    }

    private func appendCurrent() {
        guard let url = URL(string: currentLink.trimmingCharacters(in: .whitespacesAndNewlines)),
              !currentLink.isEmpty
        else { return }

        let id = currentGUID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? url.absoluteString
            : currentGUID.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawExcerpt = !currentEncoded.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? currentEncoded
            : currentDescription
        let excerpt = rawExcerpt.trimmingCharacters(in: .whitespacesAndNewlines)
        let published = RSSDateParser.parse(currentPubDate) ?? Date()

        articles.append(
            CachedArticle(
                id: id,
                feedID: feedID,
                title: title.isEmpty ? "Untitled" : title,
                url: url,
                excerpt: excerpt,
                published: published,
                fetchedAt: Date()
            )
        )
    }
}

private enum RSSDateParser {
    static func parse(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let rfc822 = DateFormatter()
        rfc822.locale = Locale(identifier: "en_US_POSIX")
        rfc822.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        if let date = rfc822.date(from: trimmed) { return date }

        return MarkdownDates.parse(trimmed)
    }
}
