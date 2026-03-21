import SwiftUI

@MainActor @Observable
final class SaveToStackAnimator {
    enum Phase: Equatable {
        case idle
        case pagesLand
        case confirmation
    }

    var phase: Phase = .idle

    // Pages Land
    var landedPages = 0
    var splitPageCount = 0

    // Confirmation
    var showConfirmation = false
    var confirmationText = ""
    var streakPulse = false
    var confirmationFadeOut = false

    // Input data
    private(set) var savedWordCount = 0
    private(set) var newPageCount = 0
    private(set) var isFirstSessionToday = false

    var isAnimating: Bool { phase != .idle }

    func start(wordCount: Int, isFirstToday: Bool, reduceMotion: Bool = false) async {
        savedWordCount = wordCount
        newPageCount = max(wordCount / 250, 1)
        isFirstSessionToday = isFirstToday
        splitPageCount = min(newPageCount, 8)
        confirmationText = "\(newPageCount) new page\(newPageCount == 1 ? "" : "s")."

        // Reduce-motion: skip animations, show final state briefly
        if reduceMotion {
            phase = .confirmation
            landedPages = splitPageCount
            showConfirmation = true
            try? await Task.sleep(for: .milliseconds(1200))
            reset()
            return
        }

        // Phase 1 — Pages Land
        phase = .pagesLand
        let pagesToLand = splitPageCount

        for i in 1...pagesToLand {
            withAnimation(.spring(duration: 0.55, bounce: 0.5)) {
                landedPages = i
            }
            if i < pagesToLand {
                try? await Task.sleep(for: .milliseconds(650))
                guard !Task.isCancelled else { reset(); return }
            }
        }

        // Let the stack settle
        try? await Task.sleep(for: .milliseconds(1200))
        guard !Task.isCancelled else { reset(); return }

        // Phase 2 — Confirmation
        phase = .confirmation
        withAnimation(.easeOut(duration: 0.2)) {
            showConfirmation = true
        }

        // Streak pulse 500ms into confirmation
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { reset(); return }
        if isFirstSessionToday {
            withAnimation(.easeOut(duration: 0.3)) {
                streakPulse = true
            } completion: {
                withAnimation(.easeOut(duration: 0.15)) {
                    self.streakPulse = false
                }
            }
        }

        // Wait for typewriter confirmation to type out (~110ms * text.count)
        let typingDuration = confirmationText.count * 110 + 200
        try? await Task.sleep(for: .milliseconds(typingDuration))
        guard !Task.isCancelled else { reset(); return }

        // Fade out
        withAnimation(.easeOut(duration: 0.4)) {
            confirmationFadeOut = true
        }

        try? await Task.sleep(for: .milliseconds(400))
        reset()
    }

    func reset() {
        phase = .idle
        landedPages = 0
        splitPageCount = 0
        showConfirmation = false
        confirmationText = ""
        streakPulse = false
        confirmationFadeOut = false
        savedWordCount = 0
        newPageCount = 0
        isFirstSessionToday = false
    }
}
