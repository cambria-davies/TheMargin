import SwiftUI

struct GhostChartView: View {
    enum Style {
        case bars
        case line
    }

    let style: Style
    var opacity: Double = 0.08
    var unlockLabel: String?
    var ghostColor: Color

    var body: some View {
        VStack(spacing: 6) {
            Canvas { context, size in
                switch style {
                case .bars:
                    drawBars(context: context, size: size)
                case .line:
                    drawLine(context: context, size: size)
                }
            }
            .opacity(opacity)

            if let label = unlockLabel, !label.isEmpty {
                Text(label)
                    .font(.literata(11))
                    .italic()
                    .foregroundStyle(ghostColor.opacity(0.4))
            }
        }
    }

    // MARK: - Bar chart rendering

    private func drawBars(context: GraphicsContext, size: CGSize) {
        let heights: [Double] = [0.30, 0.55, 0.40, 0.70, 0.45, 0.60, 0.35]
        let barCount = heights.count
        let spacing: CGFloat = 4
        let totalSpacing = spacing * CGFloat(barCount - 1)
        let barWidth = (size.width - totalSpacing) / CGFloat(barCount)

        for (index, relativeHeight) in heights.enumerated() {
            let barHeight = size.height * relativeHeight
            let x = CGFloat(index) * (barWidth + spacing)
            let y = size.height - barHeight
            let rect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
            let path = Path(roundedRect: rect, cornerRadius: 3)
            context.fill(path, with: .color(ghostColor))
        }
    }

    // MARK: - Line chart rendering

    private func drawLine(context: GraphicsContext, size: CGSize) {
        // Control points for a smooth cubic bezier wave
        let points: [CGPoint] = [
            CGPoint(x: 0, y: size.height * 0.65),
            CGPoint(x: size.width * 0.15, y: size.height * 0.35),
            CGPoint(x: size.width * 0.30, y: size.height * 0.55),
            CGPoint(x: size.width * 0.45, y: size.height * 0.20),
            CGPoint(x: size.width * 0.60, y: size.height * 0.45),
            CGPoint(x: size.width * 0.75, y: size.height * 0.30),
            CGPoint(x: size.width, y: size.height * 0.50),
        ]

        var path = Path()
        path.move(to: points[0])

        // Draw smooth cubic bezier through the points
        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let cp1 = CGPoint(x: prev.x + (curr.x - prev.x) * 0.5, y: prev.y)
            let cp2 = CGPoint(x: prev.x + (curr.x - prev.x) * 0.5, y: curr.y)
            path.addCurve(to: curr, control1: cp1, control2: cp2)
        }

        // Fill the area under the line
        var fillPath = path
        fillPath.addLine(to: CGPoint(x: size.width, y: size.height))
        fillPath.addLine(to: CGPoint(x: 0, y: size.height))
        fillPath.closeSubpath()
        context.fill(fillPath, with: .color(ghostColor.opacity(0.3)))

        // Draw the line itself
        context.stroke(path, with: .color(ghostColor), lineWidth: 2)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        GhostChartView(
            style: .bars,
            opacity: 0.08,
            unlockLabel: "4 more sessions to unlock",
            ghostColor: Color(hex: 0xE8DFD0)
        )
        .frame(height: 80)
        .padding(.horizontal, 16)

        GhostChartView(
            style: .line,
            opacity: 0.06,
            unlockLabel: "1 more session to unlock",
            ghostColor: Color(hex: 0xE8DFD0)
        )
        .frame(height: 80)
        .padding(.horizontal, 16)

        GhostChartView(
            style: .bars,
            opacity: 0.08,
            unlockLabel: nil,
            ghostColor: Color(hex: 0xE8DFD0)
        )
        .frame(height: 80)
        .padding(.horizontal, 16)
    }
    .padding()
    .background(Color(hex: 0x1A1A18))
}
