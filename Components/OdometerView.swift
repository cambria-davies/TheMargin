import SwiftUI

struct OdometerView: View {
    let value: Int
    let animated: Bool
    @Environment(\.marginTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var columnRevealed: [Bool] = []

    private var targetDigits: [Int] {
        guard value > 0 else { return [0] }
        var digits: [Int] = []
        var n = value
        while n > 0 {
            digits.insert(n % 10, at: 0)
            n /= 10
        }
        return digits
    }

    var body: some View {
        HStack(spacing: 0) {
            let digits = targetDigits
            ForEach(Array(digits.enumerated()), id: \.offset) { index, digit in
                let revealed = index < columnRevealed.count && columnRevealed[index]
                // Reveal the actual digit with opacity — never show placeholder 0s (that read as "counting up from zero").
                Text(String(digit))
                    .font(.display(28))
                    .foregroundStyle(theme.text)
                    .monospacedDigit()
                    .opacity(revealed ? 1 : 0)
                    .offset(y: revealed ? 0 : 3)
                    .id("\(index)-\(digit)")
            }
        }
        .task(id: value) {
            guard animated, !reduceMotion else {
                columnRevealed = Array(repeating: true, count: targetDigits.count)
                return
            }
            let digits = targetDigits
            columnRevealed = Array(repeating: false, count: digits.count)
            let columnCount = digits.count
            guard columnCount > 0 else { return }
            let staggerMs = columnCount > 1 ? 80 : 0
            for col in stride(from: columnCount - 1, through: 0, by: -1) {
                try? await Task.sleep(for: .milliseconds(staggerMs))
                withAnimation(.timingCurve(0.2, 0, 0.1, 1, duration: 0.5)) {
                    columnRevealed[col] = true
                }
            }
        }
    }
}
