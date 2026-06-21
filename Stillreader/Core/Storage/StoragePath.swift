import Foundation

enum StoragePath {
    static let feeds = "feeds"
    static let links = "links"
    static let state = "state"
    static let stillreaderMeta = ".stillreader"

    static let layoutDirectories = [feeds, links, state, stillreaderMeta]

    static func feed(_ slug: String) -> String { "\(feeds)/\(slug).md" }
    static func link(_ filename: String) -> String { "\(links)/\(filename).md" }
    static func feedState(_ slug: String) -> String { "\(state)/\(slug).md" }
    static let meta = "\(stillreaderMeta)/meta.yaml"
}
