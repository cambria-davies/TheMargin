import SwiftUI

struct TypewriterConfirmation: View {
    let text: String
    var audioEngine: TypewriterAudioEngine?
    @State private var visibleCharacters: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    private func inkColor(for index: Int) -> Color {
        if colorScheme == .dark {
            return MarginTheme.darkTextVariation[index % 3]
        } else {
            return MarginTheme.inkVariation[index % 3]
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.prefix(visibleCharacters).enumerated()), id: \.offset) { index, char in
                Text(String(char))
                    .font(.typewriter(16))
                    .foregroundStyle(inkColor(for: index))
                    .rotationEffect(.degrees(sin(Double(index * 13 + 7)) * 0.4))
                    .offset(y: sin(Double(index * 7 + 3)) * 0.5)
            }
        }
        .task {
            if reduceMotion {
                visibleCharacters = text.count
                return
            }
            for i in 1...text.count {
                try? await Task.sleep(for: .milliseconds(110))
                withAnimation(.easeOut(duration: 0.05)) {
                    visibleCharacters = i
                }
                if let audioEngine, !audioEngine.isMuted {
                    audioEngine.playKeyStrike()
                }
            }
        }
    }
}
