import SwiftUI

struct MarginTheme {
    let colorScheme: ColorScheme

    private var isDark: Bool { colorScheme == .dark }

    // MARK: - Theme-adaptive colors (Visual Design v2)

    var background: Color {
        isDark ? Color(hex: 0x141210) : Color(hex: 0xF5F4F1)
    }

    var surface: Color {
        isDark ? Color(hex: 0x1E1C18) : Color(hex: 0xFDFCF8)
    }

    var surfaceDark: Color {
        isDark ? Color(hex: 0x1C1A16) : Color(hex: 0xEAE8E3)
    }

    var text: Color {
        isDark ? Color(hex: 0xEAE2D4) : Color(hex: 0x1A1A1A)
    }

    var textSecondary: Color {
        isDark ? Color(hex: 0xA09888) : Color(hex: 0x4A4540)
    }

    var textTertiary: Color {
        isDark ? Color(hex: 0x787064) : Color(hex: 0x7A756C)
    }

    /// Inactive labels for Insights time-period underline tabs — neutral grey for a clear step down from active accent (see visual design v2).
    var insightsPeriodTabInactive: Color {
        isDark ? Color(hex: 0x757575) : Color(hex: 0x8A8580)
    }

    /// Structural accent: ink in Daylight, warm white in Lamplight (not a separate hue).
    var accent: Color {
        isDark ? Color(hex: 0xFFF8F0) : Color(hex: 0x1A1A1A)
    }

    var accentDim: Color {
        isDark
            ? Color(hex: 0xFFF8F0, opacity: 0.06)
            : Color(hex: 0x1A1A1A, opacity: 0.06)
    }

    var accentMid: Color {
        isDark
            ? Color(hex: 0xFFF8F0, opacity: 0.15)
            : Color(hex: 0x1A1A1A, opacity: 0.15)
    }

    var border: Color {
        isDark ? Color(hex: 0x32302A) : Color(hex: 0x1A1A1A)
    }

    var borderLight: Color {
        isDark ? Color(hex: 0x2A2824) : Color(hex: 0xD2D5D1)
    }

    /// Non-highlighted bars in Swift Charts (e.g. words-by-day). `surfaceDark` matches the Lamplight background too closely for bar marks to read.
    var chartBarMuted: Color {
        isDark
            ? Color(hex: 0xFFF8F0, opacity: 0.24)
            : Color(hex: 0xEAE8E3)
    }

    /// Small mono axis labels on charts — slightly brighter than `textSecondary` so week/day ticks stay legible on mobile.
    var chartAxisLabel: Color {
        isDark ? Color(hex: 0xC9C1B4) : Color(hex: 0x5C564C)
    }

    // MARK: - Stack (theme-adaptive)

    var stackTop: Color {
        isDark ? Color(hex: 0xF5F0E8) : Color(hex: 0xFDFCF8)
    }

    var stackMid: Color {
        isDark ? Color(hex: 0xE8E2D8) : Color(hex: 0xF5F0E8)
    }

    var stackBack: Color {
        isDark ? Color(hex: 0xDED8CE) : Color(hex: 0xEDE8E0)
    }

    /// Edge between stack pages — keep subtle so fan strips don’t read as heavy rules.
    var stackStroke: Color {
        Color(hex: 0x000000, opacity: isDark ? 0.20 : 0.12)
    }

    /// Dashed margin on the manuscript stack top page (higher opacity than `redMargin` so it reads small).
    var stackMarginLine: Color {
        Color(red: 200 / 255, green: 70 / 255, blue: 70 / 255, opacity: 0.22)
    }

    var stackRuled: Color {
        Color(hex: 0x000000, opacity: isDark ? 0.05 : 0.06)
    }

    var stackWatermark: Color {
        Color(hex: 0x000000, opacity: isDark ? 0.03 : 0.04)
    }

    var stackDogear: Color {
        isDark ? Color(hex: 0xD8D2C8) : Color(hex: 0xE8E2D8)
    }

    /// feDropShadow opacity baseline for stack layers.
    var stackShadowOpacity: Double {
        isDark ? 0.30 : 0.04
    }

    /// Composite ambient shadow under the full stack (ellipse on the “desk” below the pages).
    var stackGroundShadowOpacity: Double {
        isDark ? 0.30 : 0.14
    }

    /// Warm radial glow behind stack in Lamplight only.
    var stackGlow: Color {
        Color(hex: 0xF0EBE1, opacity: isDark ? 0.04 : 0)
    }

    // MARK: - Structural overrides (dark vs light)

    var streakDisplaySize: CGFloat {
        isDark ? 42 : 36
    }

    var progressBarHeight: CGFloat { 4 }

    /// Glow on progress bar fill in dark mode (maps to shadow radius).
    var progressBarFillGlowRadius: CGFloat {
        isDark ? 4 : 0
    }

    var progressBarFillGlowOpacity: Double {
        isDark ? 0.35 : 0
    }

    var sessionTodayBarWidth: CGFloat {
        isDark ? 4 : 3
    }

    var highlightInsightBorderWidth: CGFloat {
        isDark ? 2 : 1
    }

    /// Insight surfaces (stat grid, charts, goal card) use square corners — editorial “hard edge” look (see visual design mockup).
    var highlightInsightCornerRadius: CGFloat { 0 }

    var activeTabIndicatorWidth: CGFloat {
        isDark ? 3 : 2
    }

    /// Soft FAB shadow — dark mode adds luminous warm tint.
    var fabShadowColor: Color {
        isDark ? Color(hex: 0xFFF8F0, opacity: 0.12) : Color.black.opacity(0.18)
    }

    var fabShadowRadius: CGFloat { 16 }

    var fabShadowY: CGFloat { 4 }

    // MARK: - Shared (theme-independent)

    static let paper = Color(hex: 0xF5F0E8)
    static let paperLight = Color(hex: 0xFDFCF8)
    static let paperDark = Color(hex: 0xE8E0D0)
    static let paperShadow = Color(hex: 0xD4C8B4)
    static let inkBlack = Color(hex: 0x2A2218)
    static let inkMedium = Color(hex: 0x4A3E30)
    static let inkDark = Color(hex: 0x362E24)
    static let inkLight = Color(hex: 0x6A5E50)
    static let redMargin = Color(red: 200/255, green: 80/255, blue: 80/255, opacity: 0.15)

    static let inkVariation: [Color] = [inkBlack, inkMedium, inkDark]

    static let darkTextVariation: [Color] = [
        Color(hex: 0xEAE2D4),
        Color(hex: 0xD8CFC0),
        Color(hex: 0xE0D5C5)
    ]
}

// MARK: - Environment key

private enum MarginThemeKey: EnvironmentKey {
    static let defaultValue = MarginTheme(colorScheme: .dark)
}

extension EnvironmentValues {
    var marginTheme: MarginTheme {
        get { self[MarginThemeKey.self] }
        set { self[MarginThemeKey.self] = newValue }
    }
}
