import SwiftUI

enum StackLayerTier {
    case back, mid, top
}

/// A single page in the ManuscriptStackView stack.
struct StackPageView: View {
    @Environment(\.marginTheme) private var theme
    let index: Int
    let isTop: Bool
    let width: CGFloat
    let height: CGFloat
    /// Horizontal stagger — matches HTML mock (`variant-type-warm.html`) per-layer offsets.
    let offsetX: CGFloat
    let jitterRotation: Double
    let isFanPage: Bool
    let isHighlighted: Bool
    let showLabel: Bool
    let session: ManuscriptStackView.SessionSummary?
    let zIndex: Double
    let stackTier: StackLayerTier
    /// Subtle grain on the dashboard top sheet (spec: elevated card texture).
    var showPaperTexture: Bool = false

    private var baseFill: Color {
        switch stackTier {
        case .top: theme.stackTop
        case .mid: theme.stackMid
        case .back: theme.stackBack
        }
    }

    /// Full manuscript surface detail (ruled paper, margin, watermark, dog-ear) — only the collapsed top sheet.
    private var showManuscriptTopDecoration: Bool {
        isTop && !isFanPage
    }

    private var strokeWidth: CGFloat {
        isTop ? 0.75 : 0.5
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(baseFill)
            .overlay {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(theme.accentDim)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 1)
                    .stroke(theme.stackStroke, lineWidth: strokeWidth)
            }
            .frame(width: width, height: height)
            .overlay {
                if showPaperTexture {
                    CardPaperNoise()
                        .clipShape(RoundedRectangle(cornerRadius: 1))
                }
            }
            .overlay {
                if showManuscriptTopDecoration {
                    ManuscriptStackTopPageDecoration(width: width, height: height)
                }
            }
            .overlay { labelOverlay }
            .shadow(
                color: .black.opacity(isTop ? 0.12 : 0.08),
                radius: isTop ? 3 : 2,
                x: 0,
                y: isTop ? 2.5 : 1.5
            )
            .offset(x: offsetX)
            .rotationEffect(.degrees(jitterRotation))
            .zIndex(zIndex)
    }

    @ViewBuilder
    private var labelOverlay: some View {
        if isFanPage, showLabel, let session {
            let isToday = Calendar.current.isDateInToday(session.date)
            let dateColor: Color = isToday ? MarginTheme.inkBlack : MarginTheme.inkMedium
            HStack(alignment: .center, spacing: 6) {
                Text(session.date.formatted(.dateTime.month(.abbreviated).day()).uppercased())
                    .font(.typewriter(11))
                    .foregroundStyle(dateColor)
                Text("\(session.wordCount)w")
                    .font(.typewriter(15))
                    .foregroundStyle(MarginTheme.inkBlack)
                MoodGlyphCompactView(mood: session.mood, size: 13, color: MarginTheme.inkBlack)
            }
            .padding(.horizontal, 6)
        }
    }
}

// MARK: - Top sheet (visual design v2 + HTML mock alignment)

/// Ruled lines, dashed red margin, ghosted “M”, dog-ear, fold crease, page-depth edges — matches manuscript stack spec.
private struct ManuscriptStackTopPageDecoration: View {
    @Environment(\.marginTheme) private var theme
    let width: CGFloat
    let height: CGFloat

    /// Dog-ear from `variant-type-warm.html`: 22×24 in a 160px-wide card — not a 45° corner.
    private var earWidth: CGFloat {
        min(22 / 160 * width, width * 0.22)
    }

    private var earHeight: CGFloat {
        let raw = 24 / 160 * width
        return min(raw, max(3, height * 0.92))
    }

    private var marginX: CGFloat {
        width * 0.2
    }

    private var lineCount: Int {
        if height < 5 { return 2 }
        if height < 8 { return 4 }
        return 6
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Canvas { context, size in
                let inset: CGFloat = 1
                let innerH = size.height - inset * 2
                guard innerH > 0 else { return }

                let topPad = inset + innerH * 0.08
                let bottomPad = inset + innerH * 0.12
                let span = size.height - topPad - bottomPad
                for i in 0..<lineCount {
                    let t = lineCount == 1 ? 0.5 : CGFloat(i) / CGFloat(lineCount - 1)
                    let y = topPad + t * span
                    var line = Path()
                    line.move(to: CGPoint(x: inset, y: y))
                    line.addLine(to: CGPoint(x: size.width - inset, y: y))
                    context.stroke(
                        line,
                        with: .color(theme.stackRuled),
                        style: StrokeStyle(lineWidth: height < 6 ? 0.35 : 0.5, lineCap: .round)
                    )
                }

                var margin = Path()
                margin.move(to: CGPoint(x: marginX, y: topPad))
                margin.addLine(to: CGPoint(x: marginX, y: size.height - bottomPad + 1))
                context.stroke(
                    margin,
                    with: .color(theme.stackMarginLine),
                    style: StrokeStyle(lineWidth: height < 6 ? 0.6 : 0.8, lineCap: .round, dash: [3, 3])
                )

                var rightEdge = Path()
                rightEdge.move(to: CGPoint(x: size.width - 0.75, y: inset))
                rightEdge.addLine(to: CGPoint(x: size.width - 0.75, y: size.height - inset))
                context.stroke(
                    rightEdge,
                    with: .color(theme.stackStroke.opacity(0.5)),
                    style: StrokeStyle(lineWidth: 0.35, lineCap: .square)
                )
                var bottomEdge = Path()
                bottomEdge.move(to: CGPoint(x: inset, y: size.height - 0.75))
                bottomEdge.addLine(to: CGPoint(x: size.width - earWidth * 0.35, y: size.height - 0.75))
                context.stroke(
                    bottomEdge,
                    with: .color(theme.stackStroke.opacity(0.3)),
                    style: StrokeStyle(lineWidth: 0.35, lineCap: .square)
                )
            }

            dogEar
        }
        .clipShape(RoundedRectangle(cornerRadius: 1))
        .allowsHitTesting(false)
    }

    private var dogEar: some View {
        let w = earWidth
        let h = earHeight
        return ZStack(alignment: .topTrailing) {
            Path { p in
                p.move(to: CGPoint(x: width, y: 0))
                p.addLine(to: CGPoint(x: width - w, y: 0))
                p.addLine(to: CGPoint(x: width, y: h))
                p.closeSubpath()
            }
            .fill(theme.stackDogear)

            Path { p in
                p.move(to: CGPoint(x: width, y: 0))
                p.addLine(to: CGPoint(x: width - w, y: 0))
                p.addLine(to: CGPoint(x: width, y: h))
                p.closeSubpath()
            }
            .stroke(theme.stackStroke, lineWidth: 0.5)

            Path { p in
                p.move(to: CGPoint(x: width - w + 1, y: 1))
                p.addLine(to: CGPoint(x: width - 1, y: h - 1))
            }
            .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        }
        .frame(width: width, height: height, alignment: .topTrailing)
    }
}
