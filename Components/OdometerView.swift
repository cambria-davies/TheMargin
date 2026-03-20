import SwiftUI

struct OdometerView: View {
    let value: Int
    let animated: Bool
    @Environment(\.marginTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayValue: Int = 0

    var body: some View {
        HStack(spacing: 0) {
            let digits = String(displayValue)
            ForEach(Array(digits.enumerated()), id: \.offset) { index, digit in
                Text(String(digit))
                    .font(.display(28))
                    .foregroundStyle(theme.text)
                    .monospacedDigit()
                    .transition(.push(from: .bottom))
                    .id("\(index)-\(digit)")
            }
        }
        .task {
            guard animated else {
                displayValue = value
                return
            }
            if reduceMotion {
                displayValue = value
                return
            }
            // Animate counting up
            let steps = min(value, 20)
            guard steps > 0 else {
                displayValue = value
                return
            }
            for i in 1...steps {
                try? await Task.sleep(for: .milliseconds(25))
                withAnimation(.easeOut(duration: 0.15)) {
                    displayValue = value * i / steps
                }
            }
            withAnimation { displayValue = value }
        }
        .onChange(of: value) { _, newValue in
            if animated && !reduceMotion {
                withAnimation(.easeOut(duration: 0.5)) {
                    displayValue = newValue
                }
            } else {
                displayValue = newValue
            }
        }
    }
}
