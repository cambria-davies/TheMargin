import SwiftUI

struct MoodGlyphView: View {
    let mood: Mood
    let isSelected: Bool
    let size: CGFloat
    @Environment(\.marginTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Tracks whether glyph should be inverted (100ms after ink starts)
    @State private var glyphInverted: Bool = false
    @State private var invertTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            // ── Ink-wash fill ──────────────────────────────────────────
            inkWashFill

            // ── Unselected outline ring ────────────────────────────────
            Circle()
                .stroke(mood.color.opacity(0.6), lineWidth: 1.5)
                .opacity(isSelected ? 0 : 1)
                .animation(reduceMotion ? .linear(duration: 0.15) : .easeOut(duration: 0.3), value: isSelected)

            // ── Glyph / icon ───────────────────────────────────────────
            if mood.usesSVGIcon {
                MoodIconShape(mood: mood)
                    .stroke(
                        glyphInverted ? MarginTheme.paper : MarginTheme.inkBlack,
                        style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: size * 0.5, height: size * 0.5)
                    .animation(.linear(duration: 0.1), value: glyphInverted)
            } else {
                Text(mood.glyph)
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(glyphInverted ? MarginTheme.paper : MarginTheme.inkBlack)
                    .animation(.linear(duration: 0.1), value: glyphInverted)
            }
        }
        .frame(width: size, height: size)
        .onChange(of: isSelected) { _, selected in
            invertTask?.cancel()
            if selected {
                // Glyph inverts 100ms after ink begins spreading
                invertTask = Task {
                    try? await Task.sleep(for: .milliseconds(100))
                    guard !Task.isCancelled else { return }
                    glyphInverted = true
                }
            } else {
                // On deselect: revert glyph immediately as ink collapses
                glyphInverted = false
            }
        }
    }

    // MARK: - Ink-wash fill

    @ViewBuilder
    private var inkWashFill: some View {
        if reduceMotion {
            // Reduce Motion: plain opacity transition, no scale/blur
            Circle()
                .fill(mood.color)
                .opacity(isSelected ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.2), value: isSelected)
        } else {
            // Full ink-wash: radial gradient that spreads from center with feathered edge
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: mood.color, location: 0.0),
                            .init(color: mood.color, location: 0.72),
                            .init(color: mood.color.opacity(0.55), location: 0.88),
                            .init(color: mood.color.opacity(0.0), location: 1.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.55
                    )
                )
                // Blur adds the feathered "ink bleed" look
                .blur(radius: isSelected ? size * 0.06 : size * 0.03)
                .scaleEffect(isSelected ? 1.05 : 0.2)
                .opacity(isSelected ? 1.0 : 0.0)
                .animation(.timingCurve(0.1, 0.0, 0.2, 1.0, duration: 0.4), value: isSelected)
        }
    }
}

struct MoodIconShape: Shape {
    let mood: Mood

    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24.0
        var p = Path()
        switch mood {
        case .dry:
            p.move(to: CGPoint(x: 12*s, y: 20*s))
            p.addCurve(to: CGPoint(x: 7.5*s, y: 12.5*s),
                       control1: CGPoint(x: 9.5*s, y: 17*s),
                       control2: CGPoint(x: 8*s, y: 15*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 4*s),
                       control1: CGPoint(x: 8*s, y: 10*s),
                       control2: CGPoint(x: 10*s, y: 7*s))
            p.addCurve(to: CGPoint(x: 16.5*s, y: 12.5*s),
                       control1: CGPoint(x: 14*s, y: 7*s),
                       control2: CGPoint(x: 16*s, y: 10*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 20*s),
                       control1: CGPoint(x: 16*s, y: 15*s),
                       control2: CGPoint(x: 14.5*s, y: 17*s))
            p.move(to: CGPoint(x: 12*s, y: 20*s))
            p.addLine(to: CGPoint(x: 12*s, y: 14.5*s))
            p.addEllipse(in: CGRect(x: 10.8*s, y: 11.3*s, width: 2.4*s, height: 2.4*s))
        case .grinding:
            p.move(to: CGPoint(x: 5*s, y: 16*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 19*s),
                       control1: CGPoint(x: 6*s, y: 19*s),
                       control2: CGPoint(x: 8*s, y: 19*s))
            p.addCurve(to: CGPoint(x: 19*s, y: 16*s),
                       control1: CGPoint(x: 16*s, y: 19*s),
                       control2: CGPoint(x: 18*s, y: 19*s))
            p.addCurve(to: CGPoint(x: 18*s, y: 9*s),
                       control1: CGPoint(x: 20*s, y: 12*s),
                       control2: CGPoint(x: 20*s, y: 10*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 5*s),
                       control1: CGPoint(x: 16*s, y: 7*s),
                       control2: CGPoint(x: 14*s, y: 5*s))
            p.addCurve(to: CGPoint(x: 6*s, y: 9*s),
                       control1: CGPoint(x: 10*s, y: 5*s),
                       control2: CGPoint(x: 8*s, y: 7*s))
            p.addCurve(to: CGPoint(x: 5*s, y: 16*s),
                       control1: CGPoint(x: 4*s, y: 10*s),
                       control2: CGPoint(x: 4*s, y: 12*s))
        case .steady:
            p.move(to: CGPoint(x: 12*s, y: 19*s))
            p.addLine(to: CGPoint(x: 12*s, y: 11*s))
            p.move(to: CGPoint(x: 12*s, y: 14*s))
            p.addCurve(to: CGPoint(x: 8*s, y: 7*s),
                       control1: CGPoint(x: 9*s, y: 13*s),
                       control2: CGPoint(x: 7*s, y: 10*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 14*s),
                       control1: CGPoint(x: 11*s, y: 7*s),
                       control2: CGPoint(x: 12*s, y: 11*s))
            p.move(to: CGPoint(x: 12*s, y: 11*s))
            p.addCurve(to: CGPoint(x: 16*s, y: 4*s),
                       control1: CGPoint(x: 15*s, y: 10*s),
                       control2: CGPoint(x: 17*s, y: 7*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 11*s),
                       control1: CGPoint(x: 13*s, y: 4*s),
                       control2: CGPoint(x: 12*s, y: 8*s))
        default:
            break
        }
        return p
    }
}
