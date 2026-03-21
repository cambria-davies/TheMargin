import SwiftUI

struct ManuscriptStackView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let totalWords: Int
    let goalWords: Int?
    let size: StackSize
    let showGlow: Bool
    let animated: Bool
    let recentSessions: [SessionSummary]
    /// When true, suppress cascade animation for new pages. When flipped back to false, cascade runs.
    var holdCascade: Bool = false
    @State private var visiblePages: Int = 0
    @State private var shadowOpacity: Double = 0
    @State private var isFanned = false
    @State private var showSessionData = false
    /// Index at which "new page" amber highlight starts (pages >= this index glow amber then fade)
    @State private var newPageStartIndex: Int = .max
    @State private var cascadeTask: Task<Void, Never>?
    @State private var fanLabelTask: Task<Void, Never>?

    enum StackSize {
        case dashboard, detail, compact, thumbnail

        var width: CGFloat {
            switch self {
            case .dashboard: 240
            case .detail: 180
            case .compact: 80
            case .thumbnail: 40
            }
        }

        var pageHeight: CGFloat {
            switch self {
            case .dashboard: 9
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

    /// Lightweight session summary for fan display (avoids passing @Model objects into view).
    struct SessionSummary: Identifiable {
        let id: UUID
        let wordCount: Int
        let date: Date
        let mood: Mood
        let chapterTag: String?
    }

    init(
        totalWords: Int,
        goalWords: Int? = nil,
        size: StackSize,
        showGlow: Bool = false,
        animated: Bool = false,
        recentSessions: [SessionSummary] = [],
        holdCascade: Bool = false
    ) {
        self.totalWords = totalWords
        self.goalWords = goalWords
        self.size = size
        self.showGlow = showGlow
        self.animated = animated
        self.recentSessions = recentSessions
        self.holdCascade = holdCascade
    }

    private var effectivePages: Int {
        animated ? visiblePages : visualPages
    }

    private var visualPages: Int {
        guard totalWords > 0 else { return 0 }
        // Scale proportionally: maxPages represents ~100,000 words (a full novel)
        let referenceWords = 100_000.0
        let raw = Int(Double(totalWords) / referenceWords * Double(size.maxPages))
        return max(min(raw, size.maxPages), 1)
    }

    private var fanPageCount: Int {
        min(recentSessions.count, 5)
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
            shadowLayer
            pagesStack
        }
        .background(glowLayer)
        .frame(width: size.width + 10)
        .gesture(fanGesture)
        .modifier(StackHaptics(visiblePages: visiblePages, visualPages: visualPages))
        .task(id: animated) { await runBuildAnimation() }
        .onChange(of: visualPages) { oldValue, newValue in
            if holdCascade {
                // Modal is up — don't animate; cascade will run when holdCascade releases
                return
            }
            if newValue > visiblePages {
                runCascade(to: newValue)
            } else if newValue < visiblePages {
                // Project changed or words decreased — sync immediately
                cascadeTask?.cancel()
                withAnimation(.easeOut(duration: 0.3)) {
                    visiblePages = newValue
                    shadowOpacity = newValue > 0 ? 0.15 : 0
                }
            } else if !animated {
                visiblePages = newValue
                shadowOpacity = 0.15
            }
        }
        .onChange(of: holdCascade) { wasHeld, isHeld in
            if wasHeld && !isHeld && visualPages > visiblePages {
                // Released after save — cascade the new pages now that the dashboard is visible
                runCascade(to: visualPages)
            }
        }
        .onChange(of: isFanned) { _, fanned in
            handleFanChange(fanned)
        }
    }

    // MARK: - Layers

    @ViewBuilder
    private var glowLayer: some View {
        if showGlow && effectivePages > 0 && colorScheme == .dark {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0xC4956A, opacity: 0.08), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.width * 0.8
                    )
                )
                .frame(width: size.width * 1.5, height: CGFloat(effectivePages) * size.pageHeight * 1.5)
                .blur(radius: 20)
        }
    }

    @ViewBuilder
    private var shadowLayer: some View {
        if effectivePages > 0 {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [.black.opacity(shadowOpacity), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.width * 0.6
                    )
                )
                .frame(width: size.width * 1.1, height: 12)
                .offset(y: 6)
        }
    }

    private var pagesStack: some View {
        VStack(spacing: isFanned ? -26 : -1) {
            ForEach((0..<effectivePages).reversed(), id: \.self) { index in
                pageView(at: index)
            }
        }
    }

    private func pageView(at index: Int) -> StackPageView {
        let isTop = index == effectivePages - 1
        let fanIndex = effectivePages - 1 - index
        let isFanPage = isFanned && fanIndex < fanPageCount
        let pageH: CGFloat = isFanPage ? size.pageHeight + 14 : (isTop ? size.pageHeight + 1 : size.pageHeight)
        let session: SessionSummary? = (isFanPage && fanIndex < recentSessions.count) ? recentSessions[fanIndex] : nil
        let isNewPage = index >= newPageStartIndex

        return StackPageView(
            index: index,
            isTop: isTop,
            width: size.width,
            height: pageH,
            jitterX: jitterX(for: index),
            jitterRotation: jitterRotation(for: index),
            isFanPage: isFanPage,
            isHighlighted: isNewPage,
            showLabel: showSessionData,
            session: session,
            zIndex: isFanned ? Double(fanIndex) : Double(index)
        )
    }

    // MARK: - Fan Gesture

    private var fanGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .onEnded { _ in
                guard size == .dashboard, !recentSessions.isEmpty else { return }
                withAnimation(.spring(duration: 0.35, bounce: 0.7)) {
                    isFanned.toggle()
                }
            }
    }

    private func handleFanChange(_ fanned: Bool) {
        fanLabelTask?.cancel()
        if fanned {
            fanLabelTask = Task {
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    showSessionData = true
                }
            }
        } else {
            showSessionData = false
        }
    }

    // MARK: - Cascade Animation

    private func runCascade(to target: Int) {
        cascadeTask?.cancel()
        let startFrom = visiblePages
        newPageStartIndex = startFrom
        cascadeTask = Task {
            for i in (startFrom + 1)...target {
                withAnimation(.spring(duration: 0.28, bounce: 0.6)) {
                    visiblePages = i
                }
                if i < target {
                    try? await Task.sleep(for: .milliseconds(180))
                    guard !Task.isCancelled else { return }
                }
            }
            // Fade amber highlight after pages settle
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.5)) {
                newPageStartIndex = .max
            }
        }
    }

    // MARK: - Build Animation

    private func runBuildAnimation() async {
        guard animated else {
            visiblePages = visualPages
            shadowOpacity = 0.15
            return
        }
        if reduceMotion {
            visiblePages = visualPages
            shadowOpacity = 0.15
            return
        }
        visiblePages = 0
        shadowOpacity = 0
        let target = visualPages
        guard target > 0 else { return }
        let totalBuildMs = 800.0
        for i in 1...target {
            let tPrev = 1.0 - pow(1.0 - Double(i - 1) / Double(target), 2.2)
            let tCurr = 1.0 - pow(1.0 - Double(i) / Double(target), 2.2)
            let delayMs = max(15, Int((tCurr - tPrev) * totalBuildMs))
            try? await Task.sleep(for: .milliseconds(delayMs))
            withAnimation(.spring(duration: 0.35, bounce: 0.65)) {
                visiblePages = i
            }
            if Double(i) / Double(target) >= 0.5 {
                let shadowProgress = (Double(i) / Double(target) - 0.5) * 2.0
                shadowOpacity = 0.15 * shadowProgress
            }
        }
    }
}

// MARK: - Empty state
extension ManuscriptStackView {
    struct EmptyStateView: View {
        @Environment(\.colorScheme) private var colorScheme
        let size: StackSize

        private var pageColor: Color {
            colorScheme == .dark ? MarginTheme.paper : MarginTheme.paperLight
        }

        var body: some View {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(pageColor)
                    .frame(width: size.width, height: size.pageHeight * 3)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.08 : 0.15), radius: colorScheme == .dark ? 2 : 3, y: 1)
                Triangle()
                    .fill(MarginTheme.paperDark)
                    .frame(width: 10, height: 10)
            }
            .frame(width: size.width + 10)
        }
    }

    @ViewBuilder
    static func emptyState(size: StackSize) -> some View {
        EmptyStateView(size: size)
    }
}

private struct StackHaptics: ViewModifier {
    let visiblePages: Int
    let visualPages: Int

    func body(content: Content) -> some View {
        content
            .sensoryFeedback(.impact(weight: .light), trigger: visiblePages) { oldVal, newVal in
                newVal > oldVal && newVal < visualPages
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: visiblePages) { oldVal, _ in
                oldVal == visualPages - 1
            }
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
