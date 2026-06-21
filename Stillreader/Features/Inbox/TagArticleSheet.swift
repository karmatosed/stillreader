import SwiftUI

struct TagArticleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let feed: Feed
    let articleID: String
    let articleTitle: String
    let initialTags: [String]
    let onSave: ([String]) async -> Void

    @State private var tagsText: String
    @State private var isSaving = false

    init(
        feed: Feed,
        articleID: String,
        articleTitle: String,
        initialTags: [String],
        onSave: @escaping ([String]) async -> Void
    ) {
        self.feed = feed
        self.articleID = articleID
        self.articleTitle = articleTitle
        self.initialTags = initialTags
        self.onSave = onSave
        _tagsText = State(initialValue: initialTags.joined(separator: ", "))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(articleTitle)
                        .font(.subheadline)
                        .foregroundStyle(StillPalette.secondaryText(colorScheme))
                } header: {
                    Text("Article")
                }

                Section {
                    TextField("design, ios, inspiration", text: $tagsText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Tags")
                } footer: {
                    Text("Comma-separated. Tags are saved to your markdown state files.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(StillPalette.screenBackground(colorScheme))
            .navigationTitle("Tag article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        await onSave(tags)
        dismiss()
    }
}
