import SwiftUI

struct MoodGlyphView: View {
    let mood: Mood
    let isSelected: Bool
    let size: CGFloat
    @Environment(\.marginTheme) private var theme

    var body: some View {
        ZStack {
            Circle()
                .fill(mood.color)
                .scaleEffect(isSelected ? 1.0 : 0.3)
                .opacity(isSelected ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4), value: isSelected)

            Circle()
                .stroke(mood.color.opacity(0.6), lineWidth: 1.5)
                .opacity(isSelected ? 0 : 1)

            if mood.usesSVGIcon {
                MoodIconShape(mood: mood)
                    .stroke(
                        isSelected ? MarginTheme.paper : theme.text,
                        style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: size * 0.5, height: size * 0.5)
            } else {
                Text(mood.glyph)
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(isSelected ? MarginTheme.paper : theme.text)
            }
        }
        .frame(width: size, height: size)
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
