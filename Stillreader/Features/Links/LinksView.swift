import SwiftUI

struct LinksView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingSave = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(appState.links.filter { !$0.isRead }) { link in
                    NavigationLink {
                        LinkReaderView(link: link)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(link.title)
                            Text(link.url.host ?? "").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button("Read") {
                            Task { try? await appState.markLinkRead(link) }
                        }
                    }
                }
            }
            .navigationTitle("Links")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingSave = true } label: {
                        Label("Save", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingSave) {
                SaveLinkView()
            }
        }
    }
}

struct SaveLinkView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var urlString = ""
    @State private var title = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("URL", text: $urlString)
                TextField("Title", text: $title)
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("Save link")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                }
            }
        }
    }

    private func save() async {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespaces)) else {
            errorMessage = "Invalid URL"
            return
        }
        do {
            try await appState.saveLink(
                url: url,
                title: title.isEmpty ? (url.host ?? "Saved link") : title
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
