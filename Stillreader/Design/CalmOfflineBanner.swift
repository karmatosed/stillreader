import SwiftUI

struct CalmOfflineBanner: View {
    let message: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "icloud.slash")
                .font(.footnote)
            Text(message)
                .font(.footnote)
            Spacer()
        }
        .foregroundStyle(StillPalette.secondaryText(colorScheme))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(StillPalette.subtleFill(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal)
        .padding(.top, 4)
    }
}
