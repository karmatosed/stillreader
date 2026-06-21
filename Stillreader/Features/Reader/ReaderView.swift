import SwiftUI

struct ReaderView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    let article: CachedArticle
    let feed: Feed

    @State private var showFullArticle = false
    @State private var showingTagSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(article.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(StillPalette.primaryText(colorScheme))
                Text(feed.title)
                    .font(.subheadline)
                    .foregroundStyle(StillPalette.secondaryText(colorScheme))
                Text(article.published.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(StillPalette.tertiaryText(colorScheme))

                if showFullArticle {
                    ArticleWebView(url: article.url)
                        .frame(minHeight: 420)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else if !article.excerpt.isEmpty {
                    RichTextView(content: article.excerpt)
                }

                HStack(spacing: 12) {
                    if !showFullArticle {
                        Button("Read full article") {
                            showFullArticle = true
                        }
                        .buttonStyle(.calmBordered)
                    }
                    Button("Open in Safari") {
                        openURL(article.url)
                    }
                    .buttonStyle(.calmBordered)
                }
            }
            .padding()
        }
        .background(StillPalette.screenBackground(colorScheme))
        .navigationTitle("Reader")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Read") {
                    Task { try? await appState.markRead(feed: feed, articleID: article.id) }
                }
                .foregroundStyle(StillPalette.primaryText(colorScheme))
                Button("Later") {
                    Task { try? await appState.markReadLater(feed: feed, articleID: article.id) }
                }
                .foregroundStyle(StillPalette.primaryText(colorScheme))
                Button("Tag") {
                    showingTagSheet = true
                }
                .foregroundStyle(StillPalette.primaryText(colorScheme))
            }
        }
        .sheet(isPresented: $showingTagSheet) {
            TagArticleSheet(
                feed: feed,
                articleID: article.id,
                articleTitle: article.title,
                initialTags: appState.tags(for: feed, articleID: article.id)
            ) { tags in
                try? await appState.setArticleTags(feed: feed, articleID: article.id, tags: tags)
            }
        }
    }
}

struct LinkReaderView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    let link: SavedLink

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(link.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(StillPalette.primaryText(colorScheme))
                Text(link.url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(StillPalette.secondaryText(colorScheme))
                if !link.notes.isEmpty {
                    RichTextView(content: link.notes)
                }
                Button("Open in Safari") {
                    openURL(link.url)
                }
                .buttonStyle(.calmBordered)
            }
            .padding()
        }
        .background(StillPalette.screenBackground(colorScheme))
        .navigationTitle("Saved link")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Mark read") {
                Task { try? await appState.markLinkRead(link) }
            }
            .foregroundStyle(StillPalette.primaryText(colorScheme))
        }
    }
}
