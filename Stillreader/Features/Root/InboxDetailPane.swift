import SwiftUI

struct InboxDetailPane: View {
    @EnvironmentObject private var appState: AppState
    let selection: InboxDetailSelection?

    var body: some View {
        Group {
            if let selection {
                detail(for: selection)
            } else {
                SplitDetailPlaceholder()
            }
        }
    }

    @ViewBuilder
    private func detail(for selection: InboxDetailSelection) -> some View {
        switch selection {
        case let .article(articleID, feedID):
            if let feed = appState.feeds.first(where: { $0.id == feedID }),
               let article = appState.articles.first(where: { $0.id == articleID && $0.feedID == feedID }) {
                ReaderView(article: article, feed: feed)
            } else {
                SplitDetailPlaceholder(
                    "Article unavailable",
                    message: "This article is no longer cached.",
                    systemImage: "doc.text"
                )
            }

        case let .readLater(itemID, feedID, title, url):
            if let feed = appState.feeds.first(where: { $0.id == feedID }),
               let article = appState.articles.first(where: { $0.id == itemID && $0.feedID == feedID }) {
                ReaderView(article: article, feed: feed)
            } else if let feed = appState.feeds.first(where: { $0.id == feedID }) {
                ReadLaterFallbackView(title: title, url: url, feed: feed)
            } else {
                SplitDetailPlaceholder(
                    "Read later",
                    message: title,
                    systemImage: "bookmark"
                )
            }

        case let .link(linkID):
            if let link = appState.links.first(where: { $0.id == linkID }) {
                LinkReaderView(link: link)
            } else {
                SplitDetailPlaceholder(
                    "Link unavailable",
                    message: "This saved link could not be found.",
                    systemImage: "link"
                )
            }
        }
    }
}
