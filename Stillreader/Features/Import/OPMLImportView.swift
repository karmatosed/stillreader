import SwiftUI
import UniformTypeIdentifiers

struct OPMLImportView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var opmlText = ""
    @State private var entries: [OPMLFeed] = []
    @State private var selected: Set<URL> = []
    @State private var resultMessage: String?
    @State private var showingFilePicker = false

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button("Choose OPML file") {
                        showingFilePicker = true
                    }
                    .buttonStyle(.calmBordered)
                    Spacer()
                    Button("Preview") { preview() }
                        .buttonStyle(.calmBordered)
                }
                .padding(.horizontal)

                TextEditor(text: $opmlText)
                    .font(.body.monospaced())
                    .frame(minHeight: 120)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                    .padding()

                List(entries, id: \.url) { entry in
                    Toggle(isOn: Binding(
                        get: { selected.contains(entry.url) },
                        set: { isOn in
                            if isOn { selected.insert(entry.url) } else { selected.remove(entry.url) }
                        }
                    )) {
                        VStack(alignment: .leading) {
                            Text(entry.title)
                            Text(entry.url.absoluteString).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                if let resultMessage {
                    Text(resultMessage).font(.footnote).padding()
                }
            }
            .navigationTitle("Import OPML")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") { Task { await importSelected() } }
                        .disabled(selected.isEmpty)
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.xml, .data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case let .success(urls):
                    guard let url = urls.first else { return }
                    loadOPMLFile(url)
                case let .failure(error):
                    resultMessage = error.localizedDescription
                }
            }
        }
    }

    private func loadOPMLFile(_ url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            opmlText = String(decoding: data, as: UTF8.self)
            preview()
        } catch {
            resultMessage = error.localizedDescription
        }
    }

    private func preview() {
        do {
            entries = try OPMLParser.parse(opmlText)
            selected = Set(entries.map(\.url))
        } catch {
            resultMessage = error.localizedDescription
        }
    }

    private func importSelected() async {
        let toImport = entries.filter { selected.contains($0.url) }
        do {
            let result = try await appState.importOPMLFeeds(toImport)
            resultMessage = "\(result.imported) imported, \(result.skipped) skipped"
            if result.imported > 0 {
                dismiss()
            }
        } catch {
            resultMessage = error.localizedDescription
        }
    }
}
