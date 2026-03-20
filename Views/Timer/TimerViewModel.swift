import Foundation
import SwiftUI

@MainActor @Observable
class TimerViewModel {
    enum State: Equatable {
        case ready, running, paused, stopped
    }

    var state: State = .ready
    var elapsedSeconds: Int = 0
    var typedText: String = ""
    var carriagePosition: Double = 0
    var cursorVisible: Bool = true

    private var timerTask: Task<Void, Never>?
    private var typewriterTask: Task<Void, Never>?
    private var cursorTask: Task<Void, Never>?
    private var fullTipText: String = ""
    private var tipCharIndex: Int = 0
    private let charsPerLine = 35

    var formattedTime: String {
        let duration = Duration.seconds(elapsedSeconds)
        if elapsedSeconds >= 3600 {
            return duration.formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 1)))
        }
        return duration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 1)))
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
        cursorTask?.cancel()
    }

    func loadTip(_ tip: WritingTip?) {
        guard let tip else { return }
        fullTipText = tip.text
        if let attr = tip.attribution {
            fullTipText += "\n— \(attr)"
        }
        tipCharIndex = 0
        typedText = ""
        carriagePosition = 0
        cursorVisible = true
        cursorTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(400))
                cursorVisible.toggle()
            }
        }
    }

    private func startTimers() {
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard state == .running else { continue }
                elapsedSeconds += 1
            }
        }

        guard tipCharIndex < fullTipText.count else { return }
        typewriterTask = Task {
            try? await Task.sleep(for: .seconds(1.6))
            await beginTyping()
        }
    }

    private func beginTyping() async {
        while !Task.isCancelled, tipCharIndex < fullTipText.count {
            try? await Task.sleep(for: .milliseconds(330))
            guard state == .running else { continue }

            let index = fullTipText.index(fullTipText.startIndex, offsetBy: tipCharIndex)
            let char = fullTipText[index]
            typedText += String(char)
            tipCharIndex += 1

            let posInLine = tipCharIndex % charsPerLine
            if posInLine == 0 && tipCharIndex > 0 {
                withAnimation(.easeOut(duration: 0.15)) {
                    carriagePosition = 0
                }
            } else {
                carriagePosition = Double(posInLine) / Double(charsPerLine)
            }
        }
    }
}
