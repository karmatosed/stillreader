import SwiftUI

struct AddFeedView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var urlString = ""
    @State private var title = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                #if os(iOS)
                TextField("Feed URL", text: $urlString)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                #else
                TextField("Feed URL", text: $urlString)
                #endif
                TextField("Title (optional)", text: $title)
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red).font(.footnote)
                }
            }
            .navigationTitle("Add feed")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { Task { await addFeed() } }
                        .disabled(urlString.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addFeed() async {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespaces)) else {
            errorMessage = "Invalid URL"
            return
        }
        do {
            try await appState.addFeed(
                url: url,
                title: title.isEmpty ? nil : title
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
