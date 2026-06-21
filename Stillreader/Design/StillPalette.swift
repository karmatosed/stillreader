import SwiftUI

/// Monochrome palette — no system blue; calm, paper-like light and ink-like dark.
enum StillPalette {
    static func accent(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.94) : Color(white: 0.10)
    }

    static func screenBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.07, green: 0.07, blue: 0.08)
            : Color(red: 0.98, green: 0.98, blue: 0.97)
    }

    static func elevatedBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.11, green: 0.11, blue: 0.12)
            : Color(red: 1.0, green: 1.0, blue: 0.99)
    }

    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.94) : Color(white: 0.12)
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.58) : Color(white: 0.45)
    }

    static func tertiaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.42) : Color(white: 0.58)
    }

    static func separator(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.20) : Color(white: 0.88)
    }

    static func prominentFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.94) : Color(white: 0.12)
    }

    static func prominentLabel(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.08) : Color(white: 0.98)
    }

    static func subtleFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.16) : Color(white: 0.92)
    }

    static func selectedChipFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.22) : Color(white: 0.88)
    }

    static func link(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.78) : Color(white: 0.22)
    }
}
