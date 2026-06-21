import Foundation

struct OPMLFeed: Equatable, Sendable {
    let title: String
    let url: URL
}

enum OPMLParser {
    static func parse(_ data: Data) throws -> [OPMLFeed] {
        let xml = XMLParser(data: data)
        let delegate = OPMLParserDelegate()
        xml.delegate = delegate
        guard xml.parse() else {
            throw OPMLParserError.parseFailed
        }
        return delegate.feeds
    }

    static func parse(_ string: String) throws -> [OPMLFeed] {
        guard let data = string.data(using: .utf8) else {
            throw OPMLParserError.invalidEncoding
        }
        return try parse(data)
    }
}

enum OPMLParserError: Error {
    case parseFailed
    case invalidEncoding
}

private final class OPMLParserDelegate: NSObject, XMLParserDelegate {
    var feeds: [OPMLFeed] = []

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        guard elementName == "outline" else { return }
        guard attributeDict["type"] == "rss" || attributeDict["xmlUrl"] != nil else { return }
        guard let urlString = attributeDict["xmlUrl"], let url = URL(string: urlString) else { return }
        let title = attributeDict["title"] ?? attributeDict["text"] ?? url.host ?? "Untitled"
        feeds.append(OPMLFeed(title: title, url: url))
    }
}
