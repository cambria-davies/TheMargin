import SwiftUI

struct OdometerView: View {
    let value: Int
    let animated: Bool
    var fontSize: CGFloat = 28
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

    /// US-style grouping: comma after a digit when more digits follow and the remaining count to the right is a multiple of 3.
    private static func shouldInsertCommaAfterDigit(at index: Int, digitCount: Int) -> Bool {
        guard digitCount > 1 else { return false }
        return (digitCount - index - 1) % 3 == 0 && index < digitCount - 1
    }

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    private static func accessibilityNumberString(_ value: Int) -> String {
        decimalFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    var body: some View {
        HStack(spacing: 0) {
            let digits = targetDigits
            ForEach(Array(digits.enumerated()), id: \.offset) { index, digit in
                let revealed = index < columnRevealed.count && columnRevealed[index]
                HStack(spacing: 0) {
                    Text(String(digit))
                        .font(.displayTabular(fontSize))
                        .foregroundStyle(theme.text)
                        .monospacedDigit()
                        .opacity(revealed ? 1 : 0)
                        .offset(y: revealed ? 0 : 3)
                        .id("\(index)-\(digit)")
                    if Self.shouldInsertCommaAfterDigit(at: index, digitCount: digits.count) {
                        Text(",")
                            .font(.displayTabular(fontSize))
                            .foregroundStyle(theme.text)
                            .opacity(revealed ? 1 : 0)
                            .offset(y: revealed ? 0 : 3)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.accessibilityNumberString(value))
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
