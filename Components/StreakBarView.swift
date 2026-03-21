import SwiftUI

struct StreakBarView: View {
    let current: Int
    let longest: Int

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
                .font(.literata(10))
                .tracking(0.5)
                .foregroundStyle(theme.textFaint)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.surfaceRaised)

                    // Fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [theme.amberMid, theme.amber],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * fillFraction)
                }
                .frame(height: 6)
                .frame(maxHeight: .infinity)
            }
            .frame(height: 6)

            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text("\(current)")
                    .font(.mono(16, weight: .regular))
                    .fontWeight(.bold)
                    .foregroundStyle(theme.amber)
                    .contentTransition(.numericText())

                Text("days")
                    .font(.literata(10))
                    .foregroundStyle(theme.textFaint)
            }
        }
        .frame(height: 30)
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
        StreakBarView(current: 5, longest: 30)
        StreakBarView(current: 7, longest: 30)
        StreakBarView(current: 2, longest: 10)
        StreakBarView(current: 0, longest: 30)
        StreakBarView(current: 0, longest: 0)
    }
    .padding()
    .background(Color(hex: 0x1A1A18))
    .environment(\.marginTheme, MarginTheme(colorScheme: .dark))
}
