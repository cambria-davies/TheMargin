import SwiftUI

struct MoodDistributionView: View {
    let distribution: [Mood: Double]
    @Environment(\.marginTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Mood.allCases, id: \.self) { mood in
                let pct = distribution[mood] ?? 0
                HStack(spacing: 8) {
                    Text(mood.glyph).frame(width: 20)
                    Text(mood.displayName)
                        .font(.literata(12)).foregroundStyle(theme.textDim).frame(width: 70, alignment: .leading)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 2).fill(mood.color).frame(width: geo.size.width * pct)
                    }
                    .frame(height: 12)
                    Text("\(Int(pct * 100))%")
                        .font(.mono(10)).foregroundStyle(theme.textFaint).frame(width: 32, alignment: .trailing)
                }
            }
        }
    }
}
