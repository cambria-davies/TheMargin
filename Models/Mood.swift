import SwiftUI

enum Mood: String, Codable, CaseIterable {
    case dry, grinding, steady, flow, breakthrough

    var glyph: String {
        switch self {
        case .dry: "✎"
        case .grinding: "▪"
        case .steady: "⌇"
        case .flow: "∞"
        case .breakthrough: "✦"
        }
    }

    var usesSVGIcon: Bool {
        switch self {
        case .dry, .grinding, .steady: true
        case .flow, .breakthrough: false
        }
    }

    var displayName: String {
        switch self {
        case .dry: "Dry"
        case .grinding: "Grinding"
        case .steady: "Steady"
        case .flow: "Flow"
        case .breakthrough: "Breakthrough"
        }
    }

    var color: Color {
        switch self {
        case .dry: Color(hex: 0x7A5C50)
        case .grinding: Color(hex: 0x8A8070)
        case .steady: Color(hex: 0xA09060)
        case .flow: Color(hex: 0xC4956A)
        case .breakthrough: Color(hex: 0xD4A85C)
        }
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
