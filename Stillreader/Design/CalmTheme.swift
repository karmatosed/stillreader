import SwiftUI

struct CalmTheme: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .tint(StillPalette.accent(colorScheme))
    }
}

struct CalmStatusBar: View {
    let lastRefresh: Date?
    let isRefreshing: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            if isRefreshing {
                ProgressView()
                    .controlSize(.small)
                Text("Refreshing…")
            } else if let lastRefresh {
                Text("Last refreshed \(lastRefresh.formatted(date: .abbreviated, time: .shortened))")
            } else {
                Text("Not refreshed yet")
            }
            Spacer()
        }
        .font(.footnote)
        .foregroundStyle(StillPalette.tertiaryText(colorScheme))
        .padding(.vertical, 4)
    }
}

extension View {
    func calmTheme() -> some View {
        modifier(CalmTheme())
    }
}
