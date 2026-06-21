import SwiftUI

struct UnreadBadge: View {
    let count: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text("\(count)")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(StillPalette.prominentLabel(colorScheme))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Capsule().fill(StillPalette.prominentFill(colorScheme)))
    }
}
