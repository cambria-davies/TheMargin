import SwiftUI

/// Overlay shown during the save-to-stack ceremony.
/// Renders cascading amber-highlighted pages and typewriter confirmation.
struct SaveToStackOverlay: View {
    let animator: SaveToStackAnimator
    let audioEngine: TypewriterAudioEngine?

    var body: some View {
        VStack(spacing: 12) {
            // Cascading pages during pagesLand phase
            if animator.phase == .pagesLand {
                pagesLandView
            }

            // Typewriter confirmation during confirmation phase
            if animator.showConfirmation {
                TypewriterConfirmation(
                    text: animator.confirmationText,
                    audioEngine: audioEngine
                )
                .opacity(animator.confirmationFadeOut ? 0 : 1)
            }
        }
    }

    private var pagesLandView: some View {
        VStack(spacing: -1) {
            ForEach(0..<animator.landedPages, id: \.self) { index in
                let isNewest = index == animator.landedPages - 1
                let jitterX = CGFloat(sin(Double(index * 7 + 3)) * 1.5)
                RoundedRectangle(cornerRadius: 1)
                    .fill(
                        LinearGradient(
                            colors: isNewest
                                ? [Color(hex: 0xC4956A, opacity: 0.4), MarginTheme.paper]
                                : [MarginTheme.paper, MarginTheme.paperDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 240, height: 9)
                    .shadow(color: .black.opacity(0.08), radius: 1, y: -0.5)
                    .offset(x: jitterX)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: animator.landedPages)
    }
}
