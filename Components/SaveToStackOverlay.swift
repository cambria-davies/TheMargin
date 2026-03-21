import SwiftUI

/// Overlay shown during the save-to-stack ceremony.
/// Renders typewriter confirmation after pages land.
struct SaveToStackOverlay: View {
    let animator: SaveToStackAnimator
    let audioEngine: TypewriterAudioEngine?

    var body: some View {
        VStack(spacing: 12) {
            if animator.showConfirmation {
                TypewriterConfirmation(
                    text: animator.confirmationText,
                    audioEngine: audioEngine
                )
                .opacity(animator.confirmationFadeOut ? 0 : 1)
            }
        }
    }
}
