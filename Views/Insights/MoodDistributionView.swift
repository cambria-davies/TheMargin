import SwiftUI

struct MoodDistributionView: View {
    let distribution: [Mood: Double]
    @Environment(\.marginTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MOOD")
                .font(.mono(9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(theme.textTertiary)
                .padding(.bottom, 4)

            ForEach(Mood.allCases, id: \.self) { mood in
                let pct = distribution[mood] ?? 0
                HStack(spacing: 8) {
                    moodIcon(mood)
                        .frame(width: 20, height: 20)
                    Text(mood.displayName)
                        .font(.grotesk(12)).foregroundStyle(theme.textSecondary).frame(width: 70, alignment: .leading)
                    GeometryReader { geo in
                        let w = geo.size.width
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(theme.accentDim)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(theme.accent)
                                .frame(width: max(0, w * pct))
                        }
                    }
                    .frame(height: 12)
                    Text("\(Int(pct * 100))%")
                        .font(.mono(10)).foregroundStyle(theme.textTertiary).frame(width: 32, alignment: .trailing)
                }
            }
        }
    }

    @ViewBuilder
    private func moodIcon(_ mood: Mood) -> some View {
        MoodGlyphCompactView(mood: mood, size: 14, color: theme.text)
    }
}
