import SwiftUI

struct ManuscriptStackView: View {
    @Environment(\.colorScheme) private var colorScheme
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
    /// Increment when the Home tab is selected again so the open build animation can replay (TabView keeps views alive).
    var revealToken: Int = 0
    /// Dashboard: pass `project.id.uuidString` so `.task` id updates in the same render as `totalWords` (avoids a one-frame lag from incrementing in `onChange`). Unset for thumbnails/detail.
    var projectSelectionKey: String = ""
    @State private var internalFanExpanded = false
    @State private var visiblePages: Int = 0
    /// Set after `runBuildAnimation` finishes so `onChange(visualPages)` can cascade later growth without racing the initial build.
    @State private var hasRunBuildAnimation = false
    @State private var shadowOpacity: Double = 0
    @State private var showSessionData = false
    /// Index at which "new page" amber highlight starts (pages >= this index glow amber then fade)
    @State private var newPageStartIndex: Int = .max
    @State private var cascadeTask: Task<Void, Never>?
    @State private var fanLabelTask: Task<Void, Never>?
    /// Ignore collapse taps briefly after long-press opens fan (same lift can register as a tap).
    @State private var ignoreCollapseTapUntil: Date?
    /// Last 250-word “bucket” we’ve already reflected in animation or save ceremony (goal mode can hold `visualPages` flat across several buckets).
    @State private var lastSyncedWordBucket: Int = 0

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
        holdCascade: Bool = false,
        fanExpandedBinding: Binding<Bool>? = nil,
        onCascadeComplete: @escaping () -> Void = {},
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

    private func jitterX(for index: Int) -> CGFloat {
        let seed = Double(index * 7 + 3)
        return CGFloat(sin(seed) * Double(size.jitterRange))
    }

    private func jitterRotation(for index: Int) -> Double {
        let seed = Double(index * 13 + 7)
        return sin(seed) * size.rotationRange
    }

    /// When fanned, pages are separated — reuse stack tilt, boost it slightly, and add a small per-card spread
    /// so the fan reads like the uneven compact stack instead of a ruler-straight fan.
    private func fanJitterRotation(for index: Int) -> Double {
        let base = jitterRotation(for: index)
        let fanIndex = effectivePages - 1 - index
        let fanSpread = sin(Double(fanIndex * 4 + 2)) * 0.55
        return base * 1.75 + fanSpread
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            shadowLayer
            pagesStack
        }
        .background(glowLayer)
        .frame(width: size.width + 10)
        .gesture(fanGesture)
        .simultaneousGesture(fanCollapseTapGesture)
        .sensoryFeedback(.impact(weight: .medium), trigger: isFanned) { _, new in new }
        .modifier(StackHaptics(visiblePages: visiblePages, visualPages: visualPages))
        .task(id: "\(animated)-\(revealToken)-\(projectSelectionKey)") {
            visiblePages = 0
            shadowOpacity = 0
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
                    shadowOpacity = newValue > 0 ? 0.15 : 0
                }
                syncWordBucketTracking()
            } else if !animated {
                visiblePages = newValue
                shadowOpacity = 0.15
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
                .frame(width: size.width * 1.5, height: glowLayerFrameHeight)
                .blur(radius: 20)
                // Don’t animate glow bounds with the fan transition.
                .transaction { $0.animation = nil }
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
            jitterX: jitterX(for: index),
            jitterRotation: isFanPage ? fanJitterRotation(for: index) : jitterRotation(for: index),
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
    private func runWordGainPulseThenComplete() {
        let bucket = wordQuantaBucket
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
        newPageStartIndex = visiblePages - 1
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.easeOut(duration: 0.2)) {
                newPageStartIndex = .max
            }
            lastSyncedWordBucket = bucket
            onCascadeComplete()
        }
    }

    // MARK: - Cascade Animation

    private func runCascade(to target: Int) {
        cascadeTask?.cancel()
        let startFrom = visiblePages
        newPageStartIndex = startFrom
        if reduceMotion {
            visiblePages = target
            shadowOpacity = target > 0 ? 0.15 : 0
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
            shadowOpacity = 0.15
            syncWordBucketTracking()
            return
        }
        if reduceMotion {
            visiblePages = visualPages
            shadowOpacity = 0.15
            syncWordBucketTracking()
            return
        }
        // `.task` can run again when the view reappears; avoid resetting 0→N if already built.
        if visiblePages == visualPages, visualPages > 0 {
            shadowOpacity = 0.15
            syncWordBucketTracking()
            return
        }
        if visiblePages < visualPages, visiblePages > 0 {
            runCascade(to: visualPages)
            return
        }
        if visiblePages > visualPages {
            visiblePages = visualPages
            shadowOpacity = visualPages > 0 ? 0.15 : 0
            syncWordBucketTracking()
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
        syncWordBucketTracking()
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
