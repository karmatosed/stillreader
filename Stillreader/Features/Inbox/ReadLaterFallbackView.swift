import SwiftUI

struct ReadLaterFallbackView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let url: URL
    let feed: Feed

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(StillPalette.primaryText(colorScheme))
            Text(feed.title)
                .font(.subheadline)
                .foregroundStyle(StillPalette.secondaryText(colorScheme))
            Text("This article is no longer cached. Open it in Safari to read.")
                .font(.footnote)
                .foregroundStyle(StillPalette.tertiaryText(colorScheme))
            Button("Open in Safari") {
                openURL(url)
            }
            .buttonStyle(.calmBordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(StillPalette.screenBackground(colorScheme))
        .navigationTitle("Read later")
        .navigationBarTitleDisplayMode(.inline)
    }
}
