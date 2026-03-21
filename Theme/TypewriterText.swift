import SwiftUI

struct TypewriterText: View {
    @Environment(\.colorScheme) private var colorScheme
    let text: String
    let fontSize: CGFloat
    var inkIndices: [Int]?
    /// When true, uses ink colors (for paper surfaces). When false, adapts to color scheme.
    var onPaper: Bool = true

    private func jitterY(for index: Int) -> Double {
        let seed = Double(index * 7 + 3)
        return sin(seed) * 0.5
    }

    private func jitterRotation(for index: Int) -> Double {
        let seed = Double(index * 13 + 7)
        return sin(seed) * 0.4
    }

    private func inkColor(for index: Int) -> Color {
        if onPaper {
            if let inkIndices, index < inkIndices.count {
                return MarginTheme.inkVariation[inkIndices[index]]
            }
            return MarginTheme.inkVariation[index % 3]
        }
        // Off-paper: use theme-adaptive text colors with subtle variation
        if colorScheme == .dark {
            return MarginTheme.darkTextVariation[index % 3]
        } else {
            return MarginTheme.inkVariation[index % 3]
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, char in
                Text(String(char))
                    .font(.typewriter(fontSize))
                    .foregroundStyle(inkColor(for: index))
                    .rotationEffect(.degrees(jitterRotation(for: index)))
                    .offset(y: jitterY(for: index))
            }
        }
    }
}
