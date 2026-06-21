import Foundation

enum RootTab: String, Hashable, CaseIterable, Identifiable, Sendable {
    case inbox
    case feeds
    case links
    case search
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .inbox: return "Inbox"
        case .feeds: return "Feeds"
        case .links: return "Links"
        case .search: return "Search"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .inbox: return "tray"
        case .feeds: return "dot.radiowaves.up.forward"
        case .links: return "link"
        case .search: return "magnifyingglass"
        case .settings: return "gear"
        }
    }
}
