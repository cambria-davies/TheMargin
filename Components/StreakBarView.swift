import SwiftUI

struct StreakBarView: View {
    let current: Int

    @Environment(\.marginTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var fillFraction: Double = 0.0

    private var targetFraction: Double {
        guard current > 0 else { return 0.0 }
        return min(Double(current) / 7.0, 1.0)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text("STREAK")
                .font(.mono(10, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(theme.textTertiary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track — thin, hard-edged (Insights mockup)
                    Rectangle()
                        .fill(theme.borderLight)

                    // Fill
                    Rectangle()
                        .fill(theme.accent)
                        .shadow(
                            color: theme.accent.opacity(theme.progressBarFillGlowOpacity),
                            radius: theme.progressBarFillGlowRadius,
                            x: 0,
                            y: 0
                        )
                        .frame(width: max(0, geo.size.width * fillFraction))
                }
                .frame(height: theme.progressBarHeight)
                .frame(maxHeight: .infinity)
            }
            .frame(height: theme.progressBarHeight)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(current)")
                    .font(.displayTabular(theme.streakDisplaySize))
                    .foregroundStyle(theme.accent)
                    .contentTransition(.numericText())
                    .monospacedDigit()

                Text("days")
                    .font(.mono(9))
                    .foregroundStyle(theme.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
        }
        .frame(minHeight: 36)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current streak: \(current) days.")
        .accessibilityValue("\(current) of 7 day goal.")
        .onAppear {
            if reduceMotion {
                fillFraction = targetFraction
            } else {
                withAnimation(.smooth(duration: 0.5)) {
                    fillFraction = targetFraction
                }
            }
        }
        .onChange(of: current) { _, _ in
            if reduceMotion {
                fillFraction = targetFraction
            } else {
                withAnimation(.smooth(duration: 0.5)) {
                    fillFraction = targetFraction
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StreakBarView(current: 5)
        StreakBarView(current: 7)
        StreakBarView(current: 2)
        StreakBarView(current: 0)
        StreakBarView(current: 0)
    }
    .padding()
    .background(Color(hex: 0x141210))
    .environment(\.marginTheme, MarginTheme(colorScheme: .dark))
}
