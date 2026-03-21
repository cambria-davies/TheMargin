import SwiftUI

/// A single page in the ManuscriptStackView stack.
struct StackPageView: View {
    @Environment(\.colorScheme) private var colorScheme
    let index: Int
    let isTop: Bool
    let width: CGFloat
    let height: CGFloat
    let jitterX: CGFloat
    let jitterRotation: Double
    let isFanPage: Bool
    let isHighlighted: Bool
    let showLabel: Bool
    let session: ManuscriptStackView.SessionSummary?
    let zIndex: Double

    /// In light mode, pages use brighter white (#FFFDF7) to stand out from the cream background (#F5F0E8)
    private var pageColor: Color {
        colorScheme == .dark ? MarginTheme.paper : MarginTheme.paperLight
    }

    private var pageEdgeColor: Color {
        colorScheme == .dark ? MarginTheme.paperDark : MarginTheme.paper
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(isHighlighted ? highlightGradient : pageGradient)
            .frame(width: width, height: height)
            .overlay { labelOverlay }
            .shadow(
                color: .black.opacity(isTop ? (colorScheme == .dark ? 0.12 : 0.18) : (colorScheme == .dark ? 0.05 : 0.1)),
                radius: isTop ? (colorScheme == .dark ? 2 : 3) : (colorScheme == .dark ? 0.5 : 1),
                y: isTop ? -1 : -0.5
            )
            .offset(x: jitterX)
            .rotationEffect(.degrees(jitterRotation))
            .zIndex(zIndex)
    }

    private var pageGradient: LinearGradient {
        LinearGradient(
            colors: [pageColor, pageEdgeColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var highlightGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0xC4956A, opacity: 0.35), MarginTheme.paper],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    @ViewBuilder
    private var labelOverlay: some View {
        if isFanPage, showLabel, let session {
            let isToday = Calendar.current.isDateInToday(session.date)
            let dateColor: Color = isToday ? Color(hex: 0xC4956A) : MarginTheme.inkLight
            HStack(spacing: 6) {
                Text(session.date.formatted(.dateTime.month(.abbreviated).day()).uppercased())
                    .font(.typewriter(11))
                    .foregroundStyle(dateColor)
                Text("\(session.wordCount)w")
                    .font(.typewriter(15))
                    .foregroundStyle(MarginTheme.inkLight)
                Text(session.mood.glyph)
                    .font(.system(size: 13))
                    .foregroundStyle(session.mood.color)
            }
            .padding(.horizontal, 6)
        }
    }
}
