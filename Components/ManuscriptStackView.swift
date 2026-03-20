import SwiftUI

struct ManuscriptStackView: View {
    @Environment(\.colorScheme) private var colorScheme
    let totalWords: Int
    let goalWords: Int?
    let size: StackSize
    let showGlow: Bool

    enum StackSize {
        case dashboard, detail, compact, thumbnail

        var width: CGFloat {
            switch self {
            case .dashboard: 220
            case .detail: 180
            case .compact: 80
            case .thumbnail: 40
            }
        }

        var pageHeight: CGFloat {
            switch self {
            case .dashboard: 7
            case .detail: 6
            case .compact: 4
            case .thumbnail: 3
            }
        }

        var maxPages: Int {
            switch self {
            case .dashboard, .detail: 40
            case .compact: 20
            case .thumbnail: 15
            }
        }

        var jitterRange: CGFloat {
            switch self {
            case .dashboard, .detail: 1.5
            case .compact: 0.8
            case .thumbnail: 0.4
            }
        }

        var rotationRange: Double {
            switch self {
            case .dashboard, .detail: 0.2
            case .compact, .thumbnail: 0.1
            }
        }
    }

    init(totalWords: Int, goalWords: Int? = nil, size: StackSize, showGlow: Bool = false) {
        self.totalWords = totalWords
        self.goalWords = goalWords
        self.size = size
        self.showGlow = showGlow
    }

    private var visualPages: Int {
        let raw = totalWords / 250
        guard raw > 0 || totalWords > 0 else { return 0 }
        return max(min(raw, size.maxPages), totalWords > 0 ? 1 : 0)
    }

    private func jitterX(for index: Int) -> CGFloat {
        let seed = Double(index * 7 + 3)
        return CGFloat(sin(seed) * Double(size.jitterRange))
    }

    private func jitterRotation(for index: Int) -> Double {
        let seed = Double(index * 13 + 7)
        return sin(seed) * size.rotationRange
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Amber radial glow (dashboard only, dark mode only)
            if showGlow && visualPages > 0 {
                if colorScheme == .dark {
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: 0xC4956A, opacity: 0.08), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: size.width * 0.8
                            )
                        )
                        .frame(width: size.width * 1.5, height: CGFloat(visualPages) * size.pageHeight * 1.5)
                        .blur(radius: 20)
                }
            }

            // Shadow under the stack
            if visualPages > 0 {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [.black.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size.width * 0.6
                        )
                    )
                    .frame(width: size.width * 1.1, height: 12)
                    .offset(y: 6)
            }

            // Pages
            VStack(spacing: 0) {
                ForEach(0..<visualPages, id: \.self) { index in
                    let isTop = index == visualPages - 1
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                colors: [MarginTheme.paper, MarginTheme.paperDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: size.width,
                            height: isTop ? size.pageHeight + 1 : size.pageHeight
                        )
                        .shadow(
                            color: .black.opacity(isTop ? 0.12 : 0.05),
                            radius: isTop ? 2 : 0.5,
                            y: isTop ? -1 : -0.5
                        )
                        .offset(x: jitterX(for: index))
                        .rotationEffect(.degrees(jitterRotation(for: index)))
                }
            }
        }
        .frame(width: size.width + 10)
    }
}

// MARK: - Empty state
extension ManuscriptStackView {
    @ViewBuilder
    static func emptyState(size: StackSize) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 2)
                .fill(MarginTheme.paper)
                .frame(width: size.width, height: size.pageHeight * 3)
                .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
            Triangle()
                .fill(MarginTheme.paperDark)
                .frame(width: 10, height: 10)
        }
        .frame(width: size.width + 10)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack(spacing: 20) {
        ManuscriptStackView(totalWords: 80000, size: .dashboard, showGlow: true)
        ManuscriptStackView(totalWords: 20000, size: .detail)
        HStack(spacing: 20) {
            ManuscriptStackView(totalWords: 5000, size: .compact)
            ManuscriptStackView(totalWords: 1000, size: .thumbnail)
        }
        ManuscriptStackView.emptyState(size: .dashboard)
    }
    .padding()
    .background(Color(hex: 0x1A1A18))
}
