import SwiftUI

struct PaperSurface: ViewModifier {
    let ruledLines: Bool
    let redMargin: Bool

    init(ruledLines: Bool = true, redMargin: Bool = true) {
        self.ruledLines = ruledLines
        self.redMargin = redMargin
    }

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    MarginTheme.paperLight
                    // Paper grain noise texture
                    Canvas { context, size in
                        var rng = StableRNG(seed: 42)
                        let dotCount = Int(size.width * size.height * 0.003)
                        for _ in 0..<dotCount {
                            let x = CGFloat.random(in: 0...size.width, using: &rng)
                            let y = CGFloat.random(in: 0...size.height, using: &rng)
                            let opacity = Double.random(in: 0.02...0.06, using: &rng)
                            context.fill(
                                Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                                with: .color(.black.opacity(opacity))
                            )
                        }
                    }

                    if ruledLines {
                        RuledLinesCanvas()
                    }
                    if redMargin {
                        HStack {
                            Rectangle()
                                .fill(MarginTheme.redMargin)
                                .frame(width: 1)
                                .padding(.leading, 40)
                            Spacer()
                        }
                    }
                }
            }
            .clipShape(.rect(cornerRadius: 4))
            .shadow(color: MarginTheme.paperShadow.opacity(0.5), radius: 4, y: 2)
    }
}

/// Ruled lines drawn via Canvas (avoids GeometryReader layout side-effects).
struct RuledLinesCanvas: View {
    let lineSpacing: Double = 28

    var body: some View {
        Canvas { context, size in
            let lineCount = Int(size.height / lineSpacing)
            for i in 1...max(lineCount, 1) {
                let y = Double(i) * lineSpacing
                let path = Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(.blue.opacity(0.07)), lineWidth: 0.5)
            }
        }
    }
}

extension View {
    func paperSurface(ruledLines: Bool = true, redMargin: Bool = true) -> some View {
        modifier(PaperSurface(ruledLines: ruledLines, redMargin: redMargin))
    }
}
