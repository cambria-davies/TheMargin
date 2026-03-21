import Foundation
import SwiftUI

@MainActor @Observable
class TimerViewModel {
    enum State: Equatable {
        case ready, running, paused, stopped
    }

    var state: State = .ready
    var elapsedSeconds: Int = 0
    var completedLines: [String] = []
    var currentLine: String = ""
    var attributionText: String = ""
    var carriagePosition: Double = 0
    var cursorVisible: Bool = true
    /// Increments each time a character is struck — used to trigger strike animation
    var strikeCount: Int = 0

    // Audio/haptic callbacks — set by the view
    var onKeyStrike: (() -> Void)?
    var onBellDing: (() -> Void)?
    var onCarriageReturn: (() -> Void)?

    private var timerTask: Task<Void, Never>?
    private var typewriterTask: Task<Void, Never>?
    private var wrappedLines: [String] = []
    private var tipAttribution: String?
    private var currentLineIndex: Int = 0
    private var currentCharIndex: Int = 0
    private let charsPerLine = 35

    /// Weighted random ink color index: 60% ink-black, 25% ink-medium, 15% ink-dark
    private(set) var inkWeights: [Int] = []

    var formattedTime: String {
        let duration = Duration.seconds(elapsedSeconds)
        if elapsedSeconds >= 3600 {
            return duration.formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 1)))
        }
        return duration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 1)))
    }

    /// Whether the typewriter mechanism area should be visible
    var showMechanism: Bool {
        !currentLine.isEmpty || !completedLines.isEmpty || state == .running || !attributionText.isEmpty
    }

    func start() {
        state = .running
        startTimers()
    }

    func pause() {
        state = .paused
        timerTask?.cancel()
        typewriterTask?.cancel()
    }

    func resume() {
        state = .running
        startTimers()
    }

    func stop() {
        state = .stopped
        timerTask?.cancel()
        typewriterTask?.cancel()
    }

    func loadTip(_ tip: WritingTip?) {
        guard let tip else { return }
        wrappedLines = wordWrap(tip.text, maxWidth: charsPerLine)
        tipAttribution = tip.attribution.map { "— \($0)" }
        currentLineIndex = 0
        currentCharIndex = 0
        currentLine = ""
        completedLines = []
        attributionText = ""
        carriagePosition = 0
        cursorVisible = true
        strikeCount = 0
        // Pre-generate ink weights for total character count
        let totalChars = wrappedLines.reduce(0) { $0 + $1.count }
        inkWeights = (0..<totalChars).map { _ in weightedRandomInk() }
    }

    /// Word-wrap text into lines that don't exceed maxWidth characters.
    /// Breaks at the last space before the limit; long words without spaces
    /// are hard-broken at maxWidth.
    private func wordWrap(_ text: String, maxWidth: Int) -> [String] {
        let words = text.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        var lines: [String] = []
        var line = ""

        for word in words {
            if line.isEmpty {
                line = word
            } else if line.count + 1 + word.count <= maxWidth {
                line += " " + word
            } else {
                lines.append(line)
                line = word
            }
            // Handle words longer than maxWidth
            while line.count > maxWidth {
                let breakAt = line.index(line.startIndex, offsetBy: maxWidth)
                lines.append(String(line[..<breakAt]))
                line = String(line[breakAt...])
            }
        }
        if !line.isEmpty {
            lines.append(line)
        }
        return lines
    }

    /// Returns 0 (60%), 1 (25%), or 2 (15%) for ink-black, ink-medium, ink-dark
    private func weightedRandomInk() -> Int {
        let roll = Int.random(in: 0..<100)
        if roll < 60 { return 0 }
        if roll < 85 { return 1 }
        return 2
    }

    private func startTimers() {
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard state == .running else { continue }
                elapsedSeconds += 1
            }
        }

        guard currentLineIndex < wrappedLines.count else { return }
        typewriterTask = Task {
            // Cursor blinks twice before first character (530ms interval × 4 transitions = ~2.1s)
            for _ in 0..<4 {
                try? await Task.sleep(for: .milliseconds(530))
                cursorVisible.toggle()
            }
            cursorVisible = false
            await beginTyping()
        }
    }

    private func beginTyping() async {
        while !Task.isCancelled, currentLineIndex < wrappedLines.count {
            let lineText = wrappedLines[currentLineIndex]

            // Type each character of the current line
            while !Task.isCancelled, currentCharIndex < lineText.count {
                let jitter = Int.random(in: -15...15)
                try? await Task.sleep(for: .milliseconds(110 + jitter))
                guard state == .running else { continue }

                let index = lineText.index(lineText.startIndex, offsetBy: currentCharIndex)
                currentLine += String(lineText[index])
                currentCharIndex += 1
                strikeCount += 1

                onKeyStrike?()

                // Update carriage position within the line
                carriagePosition = Double(currentCharIndex) / Double(max(lineText.count, charsPerLine))
            }

            // Line complete — carriage return if more lines follow
            currentLineIndex += 1
            currentCharIndex = 0

            if currentLineIndex < wrappedLines.count {
                // Carriage return sequence: 30ms hold → bell → 60ms gap → 80ms slide → 120ms pause
                try? await Task.sleep(for: .milliseconds(30))
                onBellDing?()
                try? await Task.sleep(for: .milliseconds(60))
                completedLines.append(currentLine)
                currentLine = ""
                withAnimation(.easeIn(duration: 0.08)) {
                    carriagePosition = 0
                }
                onCarriageReturn?()
                try? await Task.sleep(for: .milliseconds(120))
            }
        }

        // After tip finishes typing, reveal attribution
        if !currentLine.isEmpty {
            completedLines.append(currentLine)
            currentLine = ""
        }
        if let attribution = tipAttribution {
            try? await Task.sleep(for: .milliseconds(500))
            attributionText = attribution
        }
    }
}
