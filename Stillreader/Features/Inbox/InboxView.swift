import SwiftUI

struct InboxView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            List {
                if let lastRefresh = appState.lastRefresh {
                    Section {
                        Text("Last refreshed \(lastRefresh.formatted(date: .abbreviated, time: .shortened))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(appState.inboxItems) { item in
                    inboxRow(item)
                }
            }
            .navigationTitle("Inbox")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await refresh() }
                    } label: {
                        if isRefreshing {
                            ProgressView()
                        } else {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(isRefreshing || appState.feeds.isEmpty)
                }
            }
            .refreshable { await refresh() }
        }
    }

    @ViewBuilder
    private func inboxRow(_ item: InboxItem) -> some View {
        switch item {
        case let .article(article, feed):
            NavigationLink {
                ReaderView(article: article, feed: feed)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title).font(.headline)
                    Text(feed.title).font(.caption).foregroundStyle(.secondary)
                    if !article.excerpt.isEmpty {
                        Text(article.excerpt).font(.subheadline).lineLimit(2)
                    }
                }
                .padding(.vertical, 4)
            }
            .swipeActions(edge: .leading) {
                Button("Read") {
                    Task { try? await appState.markRead(feed: feed, articleID: article.id) }
                }
                .tint(.blue)
            }
            .swipeActions(edge: .trailing) {
                Button("Later") {
                    Task { try? await appState.markReadLater(feed: feed, articleID: article.id) }
                }
                .tint(.orange)
            }
        case let .savedLink(link):
            NavigationLink {
                LinkReaderView(link: link)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(link.title).font(.headline)
                    Text("Saved link").font(.caption).foregroundStyle(.secondary)
                }
            }
        case .readLater:
            EmptyView()
        }
    }

    private func refresh() async {
        isRefreshing = true
        await appState.refreshAll()
        isRefreshing = false
    }
}
