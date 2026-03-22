import SwiftUI

struct StatCardView: View {
    let label: String
    let value: String
    let isHighlighted: Bool

    @Environment(\.marginTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    init(label: String, value: String, isHighlighted: Bool = false) {
        self.label = label
        self.value = value
        self.isHighlighted = isHighlighted
    }

    /// Matches `variant-type-fraunces.html` `.ig-val` / `.ig-label` (26px / 8px; highlighted + dark → 30px).
    private var valuePointSize: CGFloat {
        if isHighlighted, colorScheme == .dark {
            return 30
        }
        return 26
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.display(valuePointSize, weight: .semibold))
                .foregroundStyle(theme.text)
                .monospacedDigit()
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .lineSpacing(0)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(label.uppercased())
                .font(.mono(8, weight: .semibold))
                .foregroundStyle(theme.textSecondary)
                .tracking(0.1 * 8)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.top, 16)
        .padding(.leading, 14)
        .padding(.bottom, 16)
        .padding(.trailing, 10)
        .background(isHighlighted ? theme.surfaceDark : theme.surface)
        .clipShape(Rectangle())
        .overlay {
            Rectangle().strokeBorder(
                isHighlighted ? theme.accent : theme.border,
                lineWidth: isHighlighted ? theme.highlightInsightBorderWidth : 1
            )
        }
        .overlay {
            CardPaperNoise()
                .clipShape(Rectangle())
                .allowsHitTesting(false)
        }
    }
}
