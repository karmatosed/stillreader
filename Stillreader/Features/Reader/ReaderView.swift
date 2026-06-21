import SwiftUI

struct ReaderView: View {
    @EnvironmentObject private var appState: AppState
    let article: CachedArticle
    let feed: Feed

    @State private var showWebView = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(article.title).font(.title2.bold())
                Text(feed.title).font(.subheadline).foregroundStyle(.secondary)
                Text(article.published.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !article.excerpt.isEmpty {
                    Text(article.excerpt)
                }

                if showWebView {
                    ArticleWebView(url: article.url)
                        .frame(minHeight: 400)
                } else {
                    Button("Read full article") { showWebView = true }
                }
            }
            .padding()
        }
        .navigationTitle("Reader")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Read") {
                    Task { try? await appState.markRead(feed: feed, articleID: article.id) }
                }
                Button("Later") {
                    Task { try? await appState.markReadLater(feed: feed, articleID: article.id) }
                }
                Link(destination: article.url) {
                    Label("Safari", systemImage: "safari")
                }
            }
        }
    }
}

struct LinkReaderView: View {
    @EnvironmentObject private var appState: AppState
    let link: SavedLink

    @State private var showWebView = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(link.title).font(.title2.bold())
                Text(link.url.absoluteString).font(.caption).foregroundStyle(.secondary)
                if !link.notes.isEmpty { Text(link.notes) }
                if showWebView {
                    ArticleWebView(url: link.url)
                        .frame(minHeight: 400)
                } else {
                    Button("Read full article") { showWebView = true }
                }
            }
            .padding()
        }
        .navigationTitle("Saved link")
        .toolbar {
            Button("Mark read") {
                Task { try? await appState.markLinkRead(link) }
            }
        }
    }
}
