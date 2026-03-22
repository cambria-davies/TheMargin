import SwiftUI
import UIKit

@MainActor @Observable
final class SaveToStackAnimator {
    enum Phase: Equatable {
        case idle
        case pagesLand
        case confirmation
    }

    var phase: Phase = .idle

    // Confirmation
    var showConfirmation = false
    var confirmationText = ""
    var streakPulse = false
    var confirmationFadeOut = false

    // Input data
    private(set) var savedWordCount = 0
    private(set) var newPageCount = 0
    private(set) var isFirstSessionToday = false

    private var confirmationTask: Task<Void, Never>?
    private var onComplete: (() -> Void)?

    var isAnimating: Bool { phase != .idle }

    /// Begins the save ceremony; stack motion is driven by `ManuscriptStackView` cascade. Call `cascadeDidComplete()` when the stack finishes (including zero-step saves).
    func beginCeremony(wordCount: Int, isFirstToday: Bool, onComplete: @escaping () -> Void) {
        confirmationTask?.cancel()
        savedWordCount = wordCount
        newPageCount = max((wordCount + 249) / 250, 1)
        isFirstSessionToday = isFirstToday
        confirmationText = "\(newPageCount) new page\(newPageCount == 1 ? "" : "s")."
        self.onComplete = onComplete
        phase = .pagesLand
        showConfirmation = false
        confirmationFadeOut = false
        streakPulse = false
    }

    /// Called from `ManuscriptStackView` when the cascade finishes (or immediately when the visual stack does not grow).
    func cascadeDidComplete() {
        guard phase == .pagesLand else { return }
        confirmationTask?.cancel()
        confirmationTask = Task {
            await runConfirmationSequence()
        }
    }

    private func runConfirmationSequence() async {
        phase = .confirmation

        // Breath: stack motion has ended; brief stillness before the line (and parallel stats reveal).
        try? await Task.sleep(for: .milliseconds(Self.preTypingBreathMs))
        guard !Task.isCancelled else { reset(); return }

        fireLineStartHaptic()
        withAnimation(.easeOut(duration: 0.2)) {
            showConfirmation = true
        }

        let typingDuration = confirmationText.count * 110 + 200
        try? await Task.sleep(for: .milliseconds(typingDuration))
        guard !Task.isCancelled else { reset(); return }

        // Streak after the line lands so it doesn’t compete with the stack or typewriter.
        if isFirstSessionToday {
            withAnimation(.easeOut(duration: 0.3)) {
                streakPulse = true
            } completion: {
                withAnimation(.easeOut(duration: 0.15)) {
                    self.streakPulse = false
                }
            }
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { reset(); return }
        }

        withAnimation(.easeOut(duration: 0.4)) {
            confirmationFadeOut = true
        }

        try? await Task.sleep(for: .milliseconds(400))
        guard !Task.isCancelled else { reset(); return }

        fireCeremonyCompleteHaptic()
        onComplete?()
        onComplete = nil
        reset()
    }

    func reset() {
        confirmationTask?.cancel()
        confirmationTask = nil
        phase = .idle
        showConfirmation = false
        confirmationText = ""
        streakPulse = false
        confirmationFadeOut = false
        savedWordCount = 0
        newPageCount = 0
        isFirstSessionToday = false
        onComplete = nil
    }

    /// Stillness after stack motion, before typewriter + line-start haptic.
    private static var preTypingBreathMs: Int {
        UIAccessibility.isReduceMotionEnabled ? 100 : 320
    }

    private func fireLineStartHaptic() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.prepare()
        gen.impactOccurred(intensity: 0.55)
    }

    private func fireCeremonyCompleteHaptic() {
        let notif = UINotificationFeedbackGenerator()
        notif.prepare()
        notif.notificationOccurred(.success)
    }
}
