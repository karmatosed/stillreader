import SwiftUI

struct SplitDetailPlaceholder: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let message: String
    let systemImage: String

    init(
        _ title: String = "Stillreader",
        message: String = "Select an item to read",
        systemImage: String = "newspaper"
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
    }

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
                .foregroundStyle(StillPalette.primaryText(colorScheme))
        } description: {
            Text(message)
                .foregroundStyle(StillPalette.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(StillPalette.screenBackground(colorScheme))
    }
}
