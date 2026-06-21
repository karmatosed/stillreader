import SwiftUI

struct RichTextView: View {
    let content: String

    var body: some View {
        Text(RichTextFormatter.previewText(from: content))
            .font(.body)
            .foregroundStyle(.primary)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
