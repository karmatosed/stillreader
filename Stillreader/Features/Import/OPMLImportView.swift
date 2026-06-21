import SwiftUI

struct OPMLImportView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var opmlText = ""
    @State private var entries: [OPMLFeed] = []
    @State private var selected: Set<URL> = []
    @State private var resultMessage: String?

    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $opmlText)
                    .font(.body.monospaced())
                    .frame(minHeight: 120)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                    .padding()

                Button("Preview") { preview() }

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
