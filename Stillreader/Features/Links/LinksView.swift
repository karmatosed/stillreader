import SwiftUI

struct LinksView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    @Binding private var selectedLinkID: String?
    private let usesSplitNavigation: Bool

    @State private var showingSave = false

    init() {
        _selectedLinkID = .constant(nil)
        usesSplitNavigation = false
    }

    init(selectedLinkID: Binding<String?>) {
        _selectedLinkID = selectedLinkID
        usesSplitNavigation = true
    }

    var body: some View {
        Group {
            if usesSplitNavigation {
                linksList
            } else {
                NavigationStack {
                    linksList
                }
            }
        }
    }

    private var linksList: some View {
        List(appState.links.filter { !$0.isRead }) { link in
            linkRow(link)
        }
        .scrollContentBackground(.hidden)
        .background(StillPalette.screenBackground(colorScheme))
        .navigationTitle("Links")
        .navigationBarTitleDisplayMode(usesSplitNavigation ? .inline : .large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingSave = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingSave) {
            SaveLinkView()
        }
    }

    @ViewBuilder
    private func linkRow(_ link: SavedLink) -> some View {
        let label = VStack(alignment: .leading) {
            Text(link.title)
                .foregroundStyle(StillPalette.primaryText(colorScheme))
            Text(link.url.host ?? "")
                .font(.caption)
                .foregroundStyle(StillPalette.secondaryText(colorScheme))
        }

        Group {
            if usesSplitNavigation {
                Button {
                    selectedLinkID = link.id
                } label: {
                    label
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    selectedLinkID == link.id
                        ? StillPalette.selectedChipFill(colorScheme).opacity(0.35)
                        : Color.clear
                )
            } else {
                NavigationLink {
                    LinkReaderView(link: link)
                } label: {
                    label
                }
            }
        }
        .contextMenu {
            Button("Mark read") {
                Task { try? await appState.markLinkRead(link) }
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
