import SwiftUI

struct CalmProminentButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .foregroundStyle(StillPalette.prominentLabel(colorScheme))
            .background(
                StillPalette.prominentFill(colorScheme)
                    .opacity(configuration.isPressed ? 0.75 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct CalmBorderedButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(StillPalette.primaryText(colorScheme))
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(StillPalette.separator(colorScheme), lineWidth: 1)
                    .background(
                        StillPalette.elevatedBackground(colorScheme)
                            .opacity(configuration.isPressed ? 0.7 : 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct CalmChipButtonStyle: ButtonStyle {
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(isSelected ? .semibold : .regular))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundStyle(
                isSelected
                    ? StillPalette.primaryText(colorScheme)
                    : StillPalette.secondaryText(colorScheme)
            )
            .background(
                (isSelected ? StillPalette.selectedChipFill(colorScheme) : StillPalette.subtleFill(colorScheme))
                    .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .clipShape(Capsule())
    }
}

extension ButtonStyle where Self == CalmProminentButtonStyle {
    static var calmProminent: CalmProminentButtonStyle { CalmProminentButtonStyle() }
}

extension ButtonStyle where Self == CalmBorderedButtonStyle {
    static var calmBordered: CalmBorderedButtonStyle { CalmBorderedButtonStyle() }
}
