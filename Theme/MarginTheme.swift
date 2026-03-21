import SwiftUI

struct MarginTheme {
    let colorScheme: ColorScheme

    // MARK: - Theme-adaptive colors
    var background: Color {
        colorScheme == .dark ? Color(hex: 0x1A1A18) : Color(hex: 0xF5F0E8)
    }
    var surface: Color {
        colorScheme == .dark ? Color(hex: 0x242422) : Color(hex: 0xFFFDF7)
    }
    var surfaceRaised: Color {
        colorScheme == .dark ? Color(hex: 0x2E2E2A) : Color(hex: 0xF0EBE0)
    }
    var text: Color {
        colorScheme == .dark ? Color(hex: 0xE8DFD0) : Color(hex: 0x2C2418)
    }
    var textDim: Color {
        colorScheme == .dark ? Color(hex: 0x908880) : Color(hex: 0x8A7E6A)
    }
    var textFaint: Color {
        colorScheme == .dark ? Color(hex: 0x605850) : Color(hex: 0xA89E8E)
    }
    var amber: Color {
        colorScheme == .dark ? Color(hex: 0xC4956A) : Color(hex: 0xA07850)
    }
    var amberDim: Color {
        colorScheme == .dark
            ? Color(hex: 0xC4956A, opacity: 0.15)
            : Color(hex: 0xA07850, opacity: 0.12)
    }
    var amberMid: Color {
        colorScheme == .dark
            ? Color(hex: 0xC4956A, opacity: 0.4)
            : Color(hex: 0xA07850, opacity: 0.3)
    }

    // MARK: - Shared (theme-independent)
    static let paper = Color(hex: 0xF5F0E8)
    static let paperLight = Color(hex: 0xFFFDF7) // brighter white for light-mode pages (spec: surface token)
    static let paperDark = Color(hex: 0xE8E0D0)
    static let paperShadow = Color(hex: 0xD4C8B4)
    static let inkBlack = Color(hex: 0x2A2218)
    static let inkMedium = Color(hex: 0x4A3E30)
    static let inkDark = Color(hex: 0x362E24)
    static let inkLight = Color(hex: 0x6A5E50)
    static let redMargin = Color(red: 200/255, green: 80/255, blue: 80/255, opacity: 0.15)

    // MARK: - Ink variation colors (for typewriter text on paper)
    static let inkVariation: [Color] = [inkBlack, inkMedium, inkDark]

    // MARK: - Dark-mode text variation (for typewriter text on dark backgrounds)
    static let darkTextVariation: [Color] = [
        Color(hex: 0xE8DFD0),            // primary text
        Color(hex: 0xD8CFC0),            // slightly muted
        Color(hex: 0xE0D5C5)             // mid variation
    ]
}

// MARK: - Font helpers
extension Font {
    static func typewriter(_ size: CGFloat) -> Font {
        .custom("SpecialElite-Regular", size: size)
    }
    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String = switch weight {
        case .light: "Newsreader14pt-Light"
        case .semibold: "Newsreader14pt-SemiBold"
        default: "Newsreader14pt-Regular"
        }
        return .custom(name, size: size)
    }
    static func literata(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String = switch weight {
        case .light: "Literata-Light"
        case .medium: "Literata-Medium"
        default: "Literata-Regular"
        }
        return .custom(name, size: size)
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String = switch weight {
        case .light: "JetBrainsMono-Light"
        default: "JetBrainsMono-Regular"
        }
        return .custom(name, size: size)
    }
}

// MARK: - Environment key
extension EnvironmentValues {
    @Entry var marginTheme = MarginTheme(colorScheme: .dark)
}
