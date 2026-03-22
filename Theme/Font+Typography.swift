import SwiftUI

// MARK: - Display (Fraunces)

extension Font {
    /// Stat numbers, headings, streak, project names — Fraunces variable.
    /// Uses named font instances instead of `.weight` on `Fraunces-Regular`, which can double-render on screen.
    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let psName: String
        switch weight {
        case .ultraLight, .thin:
            psName = "Fraunces-Thin"
        case .light:
            psName = "Fraunces-Light"
        case .regular, .medium:
            psName = "Fraunces-Regular"
        case .semibold:
            psName = "Fraunces-SemiBold"
        case .bold:
            psName = "Fraunces-Bold"
        case .heavy, .black:
            psName = "Fraunces-Black"
        default:
            psName = "Fraunces-Regular"
        }
        return .custom(psName, size: size)
    }

    /// Fraunces for hero stats — pair with `Text.monospacedDigit()` for stable digit widths.
    static func displayTabular(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .display(size, weight: weight)
    }

    /// Fraunces italic (variable italic).
    static func displayItalic(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let psName: String
        switch weight {
        case .ultraLight, .thin:
            psName = "Fraunces-ThinItalic"
        case .light:
            psName = "Fraunces-LightItalic"
        case .regular, .medium:
            psName = "Fraunces-RegularItalic"
        case .semibold:
            psName = "Fraunces-SemiBoldItalic"
        case .bold:
            psName = "Fraunces-BoldItalic"
        case .heavy, .black:
            psName = "Fraunces-BlackItalic"
        default:
            psName = "Fraunces-RegularItalic"
        }
        return .custom(psName, size: size)
    }
}

// MARK: - Body / UI (Space Grotesk variable)

extension Font {
    /// Body, labels, nav — Space Grotesk variable.
    /// Uses named instances from `SpaceGrotesk-Variable.ttf` (`SpaceGrotesk-Regular` is not a valid PostScript name).
    static func grotesk(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let w = spaceGroteskWeight(weight)
        let psName: String
        switch w {
        case .medium:
            psName = "SpaceGrotesk-Light_Medium"
        case .semibold, .bold:
            psName = "SpaceGrotesk-Light_Bold"
        default:
            psName = "SpaceGrotesk-Light"
        }
        return .custom(psName, size: size)
    }
}

// MARK: - Metadata (Space Mono)

extension Font {
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold, .heavy, .semibold:
            return .custom("SpaceMono-Bold", size: size)
        default:
            return .custom("SpaceMono-Regular", size: size)
        }
    }
}

// MARK: - Typewriter (unchanged)

extension Font {
    static func typewriter(_ size: CGFloat) -> Font {
        .custom("SpecialElite-Regular", size: size)
    }
}

// MARK: - Private

private func spaceGroteskWeight(_ w: Font.Weight) -> Font.Weight {
    switch w {
    case .medium: .medium
    case .semibold: .semibold
    case .bold: .bold
    default: .regular
    }
}
