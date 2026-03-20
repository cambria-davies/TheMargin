import SwiftUI

struct TypewriterText: View {
    let text: String
    let fontSize: CGFloat

    private func jitterY(for index: Int) -> Double {
        let seed = Double(index * 7 + 3)
        return sin(seed) * 0.5
    }

    private func jitterRotation(for index: Int) -> Double {
        let seed = Double(index * 13 + 7)
        return sin(seed) * 0.4
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, char in
                Text(String(char))
                    .font(.typewriter(fontSize))
                    .foregroundStyle(MarginTheme.inkVariation[index % 3])
                    .rotationEffect(.degrees(jitterRotation(for: index)))
                    .offset(y: jitterY(for: index))
            }
        }
    }
}
