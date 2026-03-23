import SwiftUI

struct ManuscriptStackView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.marginTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let totalWords: Int
    /// When set (>0), stack height follows goal progress (halfway to goal ≈ half of `maxPages`; at/above goal = full stack). When nil or 0, height uses words ÷ 250 only.
    let goalWords: Int?
    let size: StackSize
    let showGlow: Bool
    let animated: Bool
    let recentSessions: [SessionSummary]
    /// When true, suppress cascade animation for new pages. When flipped back to false, cascade runs.
    var holdCascade: Bool = false
    /// When provided (e.g. dashboard), parent can observe fan state (e.g. hide “Hold to peek”).
    var fanExpandedBinding: Binding<Bool>? = nil
    /// Fires when a cascade finishes (after save) or when no cascade runs because the stack count did not step.
    /// Default is a no-op so the callback reference stays stable across renders (see Dashboard save ceremony).
    var onCascadeComplete: () -> Void = {}
    /// Fires when the initial open build animation finishes (or immediately if reduced motion / no animation).
    var onOpenBuildComplete: () -> Void = {}
    /// Increment when the Home tab is selected again so the open build animation can replay (TabView keeps views alive).
    var revealToken: Int = 0
    /// Dashboard: pass `project.id.uuidString` so `.task` id updates in the same render as `totalWords` (avoids a one-frame lag from incrementing in `onChange`). Unset for thumbnails/detail.
    var projectSelectionKey: String = ""
    @State private var internalFanExpanded = false
    @State private var visiblePages: Int = 0
    /// Set after `runBuildAnimation` finishes so `onChange(visualPages)` can cascade later growth without racing the initial build.
    @State private var hasRunBuildAnimation = false
    /// 0…1 fade-in for the ground shadow below the stack (build + static).
    @State private var groundShadowReveal: Double = 0
    @State private var showSessionData = false
    /// Index at which "new page" accent highlight starts (pages >= this index glow then fade)
    @State private var newPageStartIndex: Int = .max
    @State private var cascadeTask: Task<Void, Never>?
    @State private var fanLabelTask: Task<Void, Never>?
    @State private var pulseTask: Task<Void, Never>?
    /// Ignore collapse taps briefly after long-press opens fan (same lift can register as a tap).
    @State private var ignoreCollapseTapUntil: Date?
    /// Last 250-word “bucket” we’ve already reflected in animation or save ceremony (goal mode can hold `visualPages` flat across several buckets).
    @State private var lastSyncedWordBucket: Int = 0

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
        holdCascade: Bool = false,
        fanExpandedBinding: Binding<Bool>? = nil,
        onCascadeComplete: @escaping () -> Void = {},
        onOpenBuildComplete: @escaping () -> Void = {},
        revealToken: Int = 0,
        projectSelectionKey: String = ""
    ) {
        self.totalWords = totalWords
        self.goalWords = goalWords
        self.size = size
        self.showGlow = showGlow
        self.animated = animated
        self.recentSessions = recentSessions
        self.holdCascade = holdCascade
        self.fanExpandedBinding = fanExpandedBinding
        self.onCascadeComplete = onCascadeComplete
        self.onOpenBuildComplete = onOpenBuildComplete
        self.revealToken = revealToken
        self.projectSelectionKey = projectSelectionKey
    }

    private var fanBinding: Binding<Bool> {
        fanExpandedBinding ?? Binding(
            get: { internalFanExpanded },
            set: { internalFanExpanded = $0 }
        )
    }

    private var isFanned: Bool { fanBinding.wrappedValue }

    private var effectivePages: Int {
        animated ? visiblePages : visualPages
    }

    /// Integer “250-word buckets” from total count (used to detect gains when goal-scaled `visualPages` doesn’t step).
    private var wordQuantaBucket: Int {
        guard totalWords > 0 else { return 0 }
        return (totalWords + 249) / 250
    }

    private var visualPages: Int {
        guard totalWords > 0 else { return 0 }
        if let goal = goalWords, goal > 0 {
            let progress = min(1.0, Double(totalWords) / Double(goal))
            let pages = Int(ceil(progress * Double(size.maxPages)))
            return min(size.maxPages, max(1, pages))
        }
        let pagesFromWords = (totalWords + 249) / 250
        return min(size.maxPages, max(1, pagesFromWords))
    }

    private var fanPageCount: Int {
        min(recentSessions.count, 5)
    }

    /// Top N pages participate in the fan; capped when the visual stack is shorter than N.
    private var fanSegmentPageCount: Int {
        min(fanPageCount, effectivePages)
    }

    /// Extra height on fanned rows so typewriter session lines fit without clipping.
    private var fanPageExtraHeight: CGFloat {
        switch size {
        case .dashboard: 19
        case .detail: 14
        case .compact, .thumbnail: 10
        }
    }

    private var fanPageBodyHeight: CGFloat {
        size.pageHeight + fanPageExtraHeight
    }

    /// Vertical advance between fanned rows: ~72% of row height visible (~28% overlap) so labels stay readable.
    private var fanOverlapFraction: CGFloat { 0.28 }

    private var fanFanSpacing: CGFloat {
        -(fanPageBodyHeight * fanOverlapFraction)
    }

    /// Collapsed stack: ~8px visible strip when height allows; otherwise overlap all but 1pt.
    private var collapsedPageSpacing: CGFloat {
        let targetVisible = min(8, max(1, size.pageHeight - 1))
        return -(size.pageHeight - targetVisible)
    }

    /// Same vertical step as fan–fan spacing so the tail meets the fan block without a tighter gap.
    private var fanToRestBridgeSpacing: CGFloat {
        fanFanSpacing
    }

    /// Intrinsic height when fanned (fan segment + bridge + tail); matches `pagesStack` fan branch.
    private var estimatedFannedStackHeight: CGFloat {
        let nFan = fanSegmentPageCount
        let nRest = effectivePages - nFan
        let hFan = CGFloat(nFan) * fanPageBodyHeight + CGFloat(max(0, nFan - 1)) * fanFanSpacing
        if nRest <= 0 { return hFan }
        let hRest = CGFloat(nRest) * size.pageHeight + CGFloat(max(0, nRest - 1)) * collapsedPageSpacing
        return hFan + fanToRestBridgeSpacing + hRest
    }

    /// Page count for glow / ambient geometry. During post-build cascades, `effectivePages` animates in springs and
    /// would resize the blurred amber ellipse every frame — that reads as a full-screen shadow sweep. After the open
    /// build finishes, use the target `visualPages` so the glow stays sized to the final stack while pages land.
    private var pageCountForAmbientLayers: Int {
        if animated && !isFanned && hasRunBuildAnimation {
            return max(effectivePages, visualPages)
        }
        return effectivePages
    }

    /// Amber glow height tracks fanned stack geometry (taller rows) so the blur doesn’t leave a short band behind the stack.
    private var glowLayerFrameHeight: CGFloat {
        let legacy = CGFloat(pageCountForAmbientLayers) * size.pageHeight * 1.5
        guard isFanned, fanSegmentPageCount > 0 else { return legacy }
        return max(legacy, estimatedFannedStackHeight * 1.15)
    }

    /// Raw horizontal stagger from HTML mock (`variant-type-warm.html`), before centering.
    private func rawStackOffsetX(index: Int) -> CGFloat {
        let pattern: [CGFloat] = [2, -2, 4, -1, 3, 0]
        if index < pattern.count {
            return pattern[index]
        }
        return -0.35 * CGFloat(index - pattern.count + 1)
    }

    /// Mean of `rawStackOffsetX` for `0..<n` so the whole stack stays visually centered (no left/right drift).
    private func stackOffsetXMean(forPageCount n: Int) -> CGFloat {
        guard n > 0 else { return 0 }
        var sum: CGFloat = 0
        for i in 0..<n {
            sum += rawStackOffsetX(index: i)
        }
        return sum / CGFloat(n)
    }

    /// Horizontal stagger: irregular edges, centered on the layout so the stack doesn’t read as leaning sideways.
    private func stackOffsetX(for index: Int) -> CGFloat {
        let scale = size.width / 220
        let mean = stackOffsetXMean(forPageCount: effectivePages)
        return (rawStackOffsetX(index: index) - mean) * scale
    }

    /// Visual design v2: fixed per-layer rotations (back → front), plus a hair of jitter so pages aren’t identical.
    private func specStackRotation(fromTop: Int) -> Double {
        switch fromTop {
        case 0: return 0
        case 1: return -0.2
        case 2: return 0.35
        case 3: return -0.25
        case 4: return 0.3
        case 5: return -0.5
        default: return -0.5
        }
    }

    private func jitterRotation(for index: Int) -> Double {
        let fromTop = effectivePages - 1 - index
        let base = specStackRotation(fromTop: fromTop)
        let micro = sin(Double(index * 13 + 7)) * 0.02
        return base + micro
    }

    /// When fanned, pages are separated — reuse stack tilt, boost it slightly, and add a small per-card spread
    /// so the fan reads like the uneven compact stack instead of a ruler-straight fan.
    private func fanJitterRotation(for index: Int) -> Double {
        let fromTop = effectivePages - 1 - index
        let base = specStackRotation(fromTop: fromTop)
        let fanIndex = effectivePages - 1 - index
        let fanSpread = sin(Double(fanIndex * 4 + 2)) * 0.55
        return base * 1.75 + fanSpread
    }

    var body: some View {
        Group {
            if effectivePages > 0 {
                // Ground shadow must sit *below* the pages in layout — a ZStack behind the bottom
                // edge is fully covered by opaque sheets; offset shadows are clipped by ScrollView.
                VStack(spacing: -6) {
                    pagesStack
                    shadowLayer
                        .frame(height: groundShadowBandHeight)
                }
                .padding(.bottom, 4)
            } else {
                pagesStack
            }
        }
        .background(glowLayer)
        .frame(width: size.width + 10)
        .gesture(fanGesture)
        .simultaneousGesture(fanCollapseTapGesture)
        .sensoryFeedback(.impact(weight: .medium), trigger: isFanned) { _, new in new }
        .modifier(StackHaptics(visiblePages: visiblePages, visualPages: visualPages))
        .task(id: "\(animated)-\(revealToken)-\(projectSelectionKey)") {
            visiblePages = 0
            groundShadowReveal = 0
            hasRunBuildAnimation = false
            lastSyncedWordBucket = 0
            await runBuildAnimation()
        }
        .onChange(of: visualPages) { oldValue, newValue in
            if holdCascade {
                // Modal is up — don't animate; cascade will run when holdCascade releases
                return
            }
            if newValue > visiblePages {
                // Initial 0→N is driven by `runBuildAnimation` only. If we cascade here too, we finish
                // before `runBuildAnimation` runs and hit the early return there — no dashboard open animation.
                if visiblePages == 0 && animated && !hasRunBuildAnimation {
                    return
                }
                runCascade(to: newValue)
            } else if newValue < visiblePages {
                // Project changed or words decreased — sync immediately
                cascadeTask?.cancel()
                withAnimation(.easeOut(duration: 0.3)) {
                    visiblePages = newValue
                    groundShadowReveal = newValue > 0 ? 1 : 0
                }
                syncWordBucketTracking()
            } else if !animated {
                visiblePages = newValue
                groundShadowReveal = newValue > 0 ? 1 : 0
                syncWordBucketTracking()
            }
        }
        .onChange(of: holdCascade) { wasHeld, isHeld in
            guard wasHeld && !isHeld else { return }
            if visualPages > visiblePages {
                // Released after save — cascade the new pages now that the dashboard is visible
                runCascade(to: visualPages)
            } else if totalWords > 0, wordQuantaBucket > lastSyncedWordBucket {
                // Goal mode (or word cap) can keep `visualPages` flat while total words still advances; pulse + finish ceremony.
                runWordGainPulseThenComplete()
            } else {
                syncWordBucketTracking()
                onCascadeComplete()
            }
        }
        .onChange(of: isFanned) { _, fanned in
            handleFanChange(fanned)
        }
        .onDisappear {
            cascadeTask?.cancel()
            fanLabelTask?.cancel()
            pulseTask?.cancel()
        }
    }

    // MARK: - Layers

    @ViewBuilder
    private var glowLayer: some View {
        if showGlow && effectivePages > 0 && colorScheme == .dark {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [theme.stackGlow, .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.width * 0.8
                    )
                )
                .frame(width: size.width * 1.5, height: glowLayerFrameHeight)
                .blur(radius: 20)
                // Don’t animate glow bounds with the fan transition.
                .transaction { $0.animation = nil }
        }
    }

    /// Vertical extent of the stacked pages (used to scale the ground shadow).
    private var collapsedStackHeight: CGFloat {
        let n = effectivePages
        guard n > 0 else { return 0 }
        return CGFloat(n) * size.pageHeight + CGFloat(max(0, n - 1)) * collapsedPageSpacing
    }

    private var groundShadowFootprintHeight: CGFloat {
        if isFanned && fanSegmentPageCount > 0 {
            return estimatedFannedStackHeight
        }
        return collapsedStackHeight
    }

    /// Vertical band for the ellipse + blur so layout reserves space (avoids clipping in `ScrollView`).
    private var groundShadowBandHeight: CGFloat {
        let stackH = groundShadowFootprintHeight
        let haloH = max(22, min(40, stackH * 0.22 + 14))
        return haloH + 4
    }

    @ViewBuilder
    private var shadowLayer: some View {
        if effectivePages > 0 {
            let reveal = groundShadowReveal
            let cap = theme.stackGroundShadowOpacity
            let stackH = groundShadowFootprintHeight
            let coreW = size.width * CGFloat(1.18 + min(0.14, Double(effectivePages) * 0.015))
            let coreH: CGFloat = max(10, min(16, stackH * 0.14 + 7))
            let haloW = coreW * 1.55
            let haloH = max(22, min(40, stackH * 0.22 + 14))

            ZStack {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.black.opacity(reveal * cap * 0.26),
                                Color.black.opacity(reveal * cap * 0.08),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: haloW * 0.52
                        )
                    )
                    .frame(width: haloW, height: haloH)
                    .blur(radius: 18)
                    .offset(y: -4)
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.black.opacity(reveal * cap * 0.62),
                                Color.black.opacity(reveal * cap * 0.12),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: coreW * 0.5
                        )
                    )
                    .frame(width: coreW, height: coreH)
                    .blur(radius: 7)
                    .offset(y: -2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .transaction { $0.animation = nil }
        }
    }

    private var pagesStack: some View {
        Group {
            if isFanned && fanSegmentPageCount > 0 {
                let restCount = effectivePages - fanSegmentPageCount
                VStack(spacing: fanToRestBridgeSpacing) {
                    VStack(spacing: fanFanSpacing) {
                        ForEach(
                            Array((effectivePages - fanSegmentPageCount)..<effectivePages).reversed(),
                            id: \.self
                        ) { index in
                            pageView(at: index)
                        }
                    }
                    if restCount > 0 {
                        VStack(spacing: collapsedPageSpacing) {
                            ForEach(Array(0..<restCount).reversed(), id: \.self) { index in
                                pageView(at: index)
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: collapsedPageSpacing) {
                    ForEach((0..<effectivePages).reversed(), id: \.self) { index in
                        pageView(at: index)
                    }
                }
            }
        }
        .animation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.34, dampingFraction: 0.88), value: isFanned)
    }

    private func stackTier(for index: Int) -> StackLayerTier {
        let n = effectivePages
        guard n > 0 else { return .mid }
        let fromTop = n - 1 - index
        let t = max(1, n / 3)
        if fromTop < t { return .top }
        if fromTop < t * 2 { return .mid }
        return .back
    }

    private func pageView(at index: Int) -> StackPageView {
        let isTop = index == effectivePages - 1
        let fanIndex = effectivePages - 1 - index
        let isFanPage = isFanned && fanIndex < fanPageCount
        let pageH: CGFloat = isFanPage
            ? fanPageBodyHeight
            : (isTop ? size.pageHeight + 1 : size.pageHeight)
        let session: SessionSummary? = (isFanPage && fanIndex < recentSessions.count) ? recentSessions[fanIndex] : nil
        let isNewPage = index >= newPageStartIndex

        return StackPageView(
            index: index,
            isTop: isTop,
            width: size.width,
            height: pageH,
            offsetX: stackOffsetX(for: index),
            jitterRotation: isFanPage ? fanJitterRotation(for: index) : jitterRotation(for: index),
            isFanPage: isFanPage,
            isHighlighted: isNewPage,
            showLabel: showSessionData,
            session: session,
            zIndex: isFanned ? Double(fanIndex) : Double(index),
            stackTier: stackTier(for: index),
            showPaperTexture: size == .dashboard && isTop && !isFanPage
        )
    }

    // MARK: - Fan Gesture

    private var fanGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .onEnded { _ in
                guard size == .dashboard, !recentSessions.isEmpty else { return }
                fanBinding.wrappedValue.toggle()
                if fanBinding.wrappedValue {
                    ignoreCollapseTapUntil = Date().addingTimeInterval(0.3)
                }
            }
    }

    private var fanCollapseTapGesture: some Gesture {
        TapGesture()
            .onEnded { _ in
                guard isFanned else { return }
                if let until = ignoreCollapseTapUntil, Date() < until {
                    return
                }
                fanBinding.wrappedValue = false
            }
    }

    private func handleFanChange(_ fanned: Bool) {
        fanLabelTask?.cancel()
        if fanned {
            fanLabelTask = Task {
                let delayMs: UInt64 = reduceMotion ? 0 : 100
                if delayMs > 0 {
                    try? await Task.sleep(for: .milliseconds(delayMs))
                }
                guard !Task.isCancelled else { return }
                withAnimation(reduceMotion ? .linear(duration: 0.15) : .easeOut(duration: 0.2)) {
                    showSessionData = true
                }
            }
        } else {
            showSessionData = false
        }
    }

    // MARK: - Word bucket (save ceremony when `visualPages` doesn’t step)

    private func syncWordBucketTracking() {
        lastSyncedWordBucket = wordQuantaBucket
    }

    /// Goal mode or 40-page cap can leave `visualPages` unchanged across a save; still give visible feedback and finish the ceremony.
    /// When several 250-word buckets land at once, staggers highlight down the stack (same cadence as `runCascade`) so it reads like multiple sheets, not a single top pulse.
    private func runWordGainPulseThenComplete() {
        let bucket = wordQuantaBucket
        let bucketDelta = bucket - lastSyncedWordBucket
        if reduceMotion {
            lastSyncedWordBucket = bucket
            onCascadeComplete()
            return
        }
        guard visiblePages > 0 else {
            lastSyncedWordBucket = bucket
            onCascadeComplete()
            return
        }
        let steps = min(max(1, bucketDelta), 8)
        pulseTask?.cancel()
        pulseTask = Task { @MainActor in
            for step in 1...steps {
                let expandDepth = min(step, visiblePages)
                let startIdx = visiblePages - expandDepth
                withAnimation(.spring(duration: 0.28, bounce: 0.6)) {
                    newPageStartIndex = startIdx
                }
                if step < steps {
                    try? await Task.sleep(for: .milliseconds(180))
                    guard !Task.isCancelled else { return }
                }
            }
            syncWordBucketTracking()
            onCascadeComplete()
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.5)) {
                newPageStartIndex = .max
            }
        }
    }

    // MARK: - Cascade Animation

    private func runCascade(to target: Int) {
        cascadeTask?.cancel()
        let startFrom = visiblePages
        newPageStartIndex = startFrom
        if reduceMotion {
            visiblePages = target
            groundShadowReveal = target > 0 ? 1 : 0
            newPageStartIndex = .max
            syncWordBucketTracking()
            onCascadeComplete()
            return
        }
        if startFrom >= target {
            syncWordBucketTracking()
            onCascadeComplete()
            return
        }
        cascadeTask = Task { @MainActor in
            for i in (startFrom + 1)...target {
                withAnimation(.spring(duration: 0.28, bounce: 0.6)) {
                    visiblePages = i
                    groundShadowReveal = Double(i) / Double(target)
                }
                if i < target {
                    try? await Task.sleep(for: .milliseconds(180))
                    guard !Task.isCancelled else { return }
                }
            }
            // Hand off to confirmation while amber highlight still reads as “new”
            syncWordBucketTracking()
            onCascadeComplete()
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
        defer { hasRunBuildAnimation = true }
        guard animated else {
            visiblePages = visualPages
            groundShadowReveal = visualPages > 0 ? 1 : 0
            syncWordBucketTracking()
            onOpenBuildComplete()
            return
        }
        if reduceMotion {
            visiblePages = visualPages
            groundShadowReveal = visualPages > 0 ? 1 : 0
            syncWordBucketTracking()
            onOpenBuildComplete()
            return
        }
        // `.task` can run again when the view reappears; avoid resetting 0→N if already built.
        if visiblePages == visualPages, visualPages > 0 {
            groundShadowReveal = 1
            syncWordBucketTracking()
            onOpenBuildComplete()
            return
        }
        if visiblePages < visualPages, visiblePages > 0 {
            runCascade(to: visualPages)
            onOpenBuildComplete()
            return
        }
        if visiblePages > visualPages {
            visiblePages = visualPages
            groundShadowReveal = visualPages > 0 ? 1 : 0
            syncWordBucketTracking()
            onOpenBuildComplete()
            return
        }
        visiblePages = 0
        groundShadowReveal = 0
        let target = visualPages
        guard target > 0 else {
            onOpenBuildComplete()
            return
        }
        let totalBuildMs = 360.0
        for i in 1...target {
            let tPrev = 1.0 - pow(1.0 - Double(i - 1) / Double(target), 2.2)
            let tCurr = 1.0 - pow(1.0 - Double(i) / Double(target), 2.2)
            let delayMs = max(15, Int((tCurr - tPrev) * totalBuildMs))
            try? await Task.sleep(for: .milliseconds(delayMs))
            withAnimation(.spring(duration: 0.35, bounce: 0.65)) {
                visiblePages = i
                groundShadowReveal = Double(i) / Double(target)
            }
        }
        syncWordBucketTracking()
        onOpenBuildComplete()
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
    .background(Color(hex: 0x141210))
}
