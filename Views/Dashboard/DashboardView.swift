import SwiftData
import SwiftUI

struct DashboardView: View {
    let homeRevealToken: Int

    @Environment(\.marginTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Query(filter: #Predicate<Project> { !$0.isArchived },
           sort: \Project.createdAt)
    private var projects: [Project]
    // NOTE: Loads all sessions — streak calculation needs the full date history.
    // The streak result is cached via @State to avoid recalculating on every body eval.
    @Query(sort: \Session.date, order: .reverse)
    private var allSessions: [Session]

    @AppStorage("lastUsedProjectID") private var lastUsedProjectID: String = ""
    @AppStorage("marginColorScheme") private var marginColorScheme = "system"

    @State private var showTimerScreen = false
    @State private var showLogSession = false
    @State private var showSettings = false

    @State private var showStats = false
    @State private var showProgress = false
    @State private var showStreak = false
    @State private var showFAB = false
    @State private var progressBarFill: Double = 0

    @State private var saveAnimator = SaveToStackAnimator()
    @State private var saveAudioEngine: TypewriterAudioEngine?
    @State private var pendingSaveWordCount: Int?
    @State private var holdStackCascade = false
    @State private var isManuscriptStackFanned = false
    @State private var cachedStreak = StreakResult(current: 0, longest: 0, atRisk: false)
    @State private var sessionDates: [Date] = []

    private var secondaryFocusOpacity: Double { 1.0 }

    private var currentProject: Project? {
        projects.first(where: { $0.id.uuidString == lastUsedProjectID }) ?? projects.first
    }

    private var recentSessionSummaries: [ManuscriptStackView.SessionSummary] {
        guard let project = currentProject else { return [] }
        return project.sessions
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map { ManuscriptStackView.SessionSummary(
                id: $0.id,
                wordCount: $0.wordCount,
                date: $0.date,
                mood: $0.mood,
                chapterTag: $0.chapterTag
            )}
    }

    private var isFirstSessionToday: Bool {
        let calendar = Calendar.current
        let todaySessions = allSessions.filter { calendar.isDate($0.date, inSameDayAs: .now) }
        return todaySessions.count <= 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if let project = currentProject {
                            VStack(spacing: 2) {
                                ManuscriptStackView(
                                    totalWords: project.totalWords,
                                    goalWords: project.wordCountGoal > 0 ? project.wordCountGoal : nil,
                                    size: .dashboard,
                                    showGlow: true,
                                    animated: true,
                                    recentSessions: recentSessionSummaries,
                                    holdCascade: holdStackCascade,
                                    fanExpandedBinding: $isManuscriptStackFanned,
                                    onCascadeComplete: handleStackCascadeComplete,
                                    onOpenBuildComplete: handleOpenBuildComplete,
                                    revealToken: homeRevealToken,
                                    projectSelectionKey: project.id.uuidString
                                )
                                .id(project.id)
                                .padding(.top, 16)

                                if !project.sessions.isEmpty {
                                    ZStack(alignment: .top) {
                                        if saveAnimator.showConfirmation {
                                            TypewriterConfirmation(
                                                text: saveAnimator.confirmationText,
                                                audioEngine: saveAudioEngine
                                            )
                                            .opacity(saveAnimator.confirmationFadeOut ? 0 : 1)
                                        } else if !isManuscriptStackFanned {
                                            Text("Hold to peek")
                                                .font(.displayItalic(11, weight: .regular))
                                                .foregroundStyle(theme.textSecondary)
                                                .tracking(0.04 * 11)
                                                .opacity(secondaryFocusOpacity)
                                        }
                                    }
                                    .frame(minHeight: 24, alignment: .top)
                                    .padding(.top, -2)
                                }
                            }

                            // Hero stats
                            VStack(spacing: 6) {
                                OdometerView(
                                    value: project.totalWords,
                                    animated: saveAnimator.phase == .idle && !holdStackCascade,
                                    fontSize: 52
                                )
                                .id("\(project.id)-hero-total")
                                Text("words")
                                    .font(.mono(9))
                                    .foregroundStyle(theme.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(0.12 * 9)

                                let today = project.wordsToday
                                if today > 0 {
                                    HStack(spacing: 2) {
                                        Text("+")
                                            .font(.mono(11))
                                            .foregroundStyle(theme.textSecondary)
                                        Text(Self.formatDecimal(today))
                                            .font(.mono(11))
                                            .foregroundStyle(theme.accent)
                                        Text("today")
                                            .font(.mono(11))
                                            .foregroundStyle(theme.textSecondary)
                                    }
                                }
                            }
                            .opacity(showStats ? secondaryFocusOpacity : 0)
                            .offset(y: showStats ? 0 : 10)

                            if project.wordCountGoal > 0 {
                                let progress = project.goalProgress
                                VStack(spacing: 4) {
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(theme.borderLight)
                                            .frame(width: 220, height: theme.progressBarHeight)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(theme.accent)
                                            .frame(width: 220 * progressBarFill, height: theme.progressBarHeight)
                                            .shadow(
                                                color: colorScheme == .dark
                                                    ? theme.accent.opacity(theme.progressBarFillGlowOpacity)
                                                    : .clear,
                                                radius: theme.progressBarFillGlowRadius
                                            )
                                    }

                                    Text("\(Int(progress * 100))%")
                                        .font(.displayTabular(16, weight: .semibold))
                                        .foregroundStyle(theme.textSecondary)
                                        .monospacedDigit()
                                }
                                .opacity(showProgress ? secondaryFocusOpacity : 0)
                                .offset(y: showProgress ? 0 : 10)
                                .onChange(of: showProgress) { _, visible in
                                    if visible {
                                        withAnimation(.easeOut(duration: 1.0)) {
                                            progressBarFill = progress
                                        }
                                    }
                                }
                                .onChange(of: progress) { _, newProgress in
                                    guard !saveAnimator.isAnimating else { return }
                                    withAnimation(.easeOut(duration: 0.8)) {
                                        progressBarFill = newProgress
                                    }
                                }
                                .onChange(of: saveAnimator.phase) { _, newPhase in
                                    if newPhase == .confirmation {
                                        let p = project.goalProgress
                                        withAnimation(.easeOut(duration: 0.75)) {
                                            progressBarFill = p
                                        }
                                    }
                                }
                            }
                        } else {
                            ManuscriptStackView.emptyState(size: .dashboard)
                                .padding(.top, 16)
                            Text("Create a project to get started")
                                .font(.grotesk(14))
                                .foregroundStyle(theme.textSecondary)
                        }

                        if let project = currentProject, project.sessions.isEmpty {
                            VStack(spacing: 8) {
                                Text("The blank page has met its match.")
                                    .font(.grotesk(14))
                                    .italic()
                                    .foregroundStyle(theme.textSecondary)
                                Text("Tap the pen to log your first session.")
                                    .font(.grotesk(11))
                                    .foregroundStyle(theme.textTertiary)
                            }
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 44)
                            .opacity(showStreak ? 1 : 0)
                            .offset(y: showStreak ? 0 : 10)
                        } else if currentProject != nil {
                            streakStackCard
                                .opacity(showStreak ? secondaryFocusOpacity : 0)
                                .offset(y: showStreak ? 0 : 10)
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.top, 20)
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        PenFABView(
                            onStartSession: { showTimerScreen = true },
                            onLogSession: { showLogSession = true }
                        )
                        .opacity(showFAB ? secondaryFocusOpacity : 0)
                        .scaleEffect(showFAB ? 1 : 0)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(projects) { project in
                            Button(project.name) {
                                lastUsedProjectID = project.id.uuidString
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(currentProject?.name ?? "No project")
                                .font(.grotesk(12))
                                .foregroundStyle(theme.text)
                                .lineLimit(1)
                            Image(systemName: "arrowtriangle.down.fill")
                                .font(.system(size: 7))
                                .foregroundStyle(theme.text)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            cycleColorScheme()
                        } label: {
                            Image(systemName: schemeToggleIcon)
                                .foregroundStyle(theme.textSecondary)
                        }
                        .accessibilityLabel("Toggle color scheme")

                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showTimerScreen, onDismiss: handleTimerDismiss) {
                TimerView(onSave: { wordCount in
                    pendingSaveWordCount = wordCount
                    holdStackCascade = true
                })
            }
            .sheet(isPresented: $showLogSession, onDismiss: handleLogSessionDismiss) {
                LogSessionView(
                    prefilledDuration: nil,
                    onSave: { wordCount in
                        pendingSaveWordCount = wordCount
                        holdStackCascade = true
                    }
                )
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onChange(of: lastUsedProjectID) { _, _ in
                isManuscriptStackFanned = false
            }
            .task {
                sessionDates = allSessions.map(\.date)
                cachedStreak = StreakCalculator.calculate(sessionDates: sessionDates)
            }
            .onChange(of: allSessions.count) { _, _ in
                sessionDates = allSessions.map(\.date)
                cachedStreak = StreakCalculator.calculate(sessionDates: sessionDates)
            }
            .task(id: homeRevealToken) {
                showStats = false
                showProgress = false
                showStreak = false
                showFAB = false
                progressBarFill = 0
                if currentProject == nil {
                    showStats = true
                    showProgress = true
                    showStreak = true
                    showFAB = true
                    progressBarFill = 0
                }
            }
        }
    }

    private var schemeToggleIcon: String {
        switch marginColorScheme {
        case "light": "sun.max.fill"
        case "dark": "moon.fill"
        default: "circle.lefthalf.filled"
        }
    }

    private func cycleColorScheme() {
        switch marginColorScheme {
        case "system": marginColorScheme = "light"
        case "light": marginColorScheme = "dark"
        default: marginColorScheme = "system"
        }
    }

    private func handleOpenBuildComplete() {
        if reduceMotion {
            showStats = true
            showProgress = true
            showStreak = true
            showFAB = true
            progressBarFill = currentProject?.goalProgress ?? 0
            return
        }
        Task { await runDashboardRevealSequence() }
    }

    @MainActor
    private func runDashboardRevealSequence() async {
        withAnimation(.easeOut(duration: 0.9)) {
            showStats = true
        }
        try? await Task.sleep(for: .milliseconds(920))
        withAnimation(.easeOut(duration: 1.0)) {
            showProgress = true
        }
        try? await Task.sleep(for: .milliseconds(200))
        withAnimation(.easeOut(duration: 0.35)) {
            showStreak = true
        }
        try? await Task.sleep(for: .milliseconds(240))
        withAnimation(.spring(response: 0.25, dampingFraction: 0.72)) {
            showFAB = true
        }
    }

    private var streakStackCard: some View {
        ZStack(alignment: .topLeading) {
            // Stacked-note card (v2): three sharp rectangles, 4pt offset; back two are outline-only.
            ForEach(0..<3, id: \.self) { i in
                Rectangle()
                    .stroke(theme.border.opacity(0.35), lineWidth: 1)
                    .background(
                        Rectangle()
                            .fill(i == 2 ? theme.surface : Color.clear)
                    )
                    .offset(x: CGFloat(i) * 4, y: CGFloat(i) * 4)
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 0) {
                    HStack(alignment: .center, spacing: 8) {
                        Text("\(cachedStreak.current)")
                            .font(.display(theme.streakDisplaySize, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(theme.accent)
                            .scaleEffect(saveAnimator.streakPulse ? 1.15 : 1.0)
                        Text("day streak")
                            .font(.grotesk(11))
                            .foregroundStyle(theme.textSecondary)
                            .textCase(.lowercase)
                    }
                    Spacer(minLength: 12)
                    Text("best: \(cachedStreak.longest)")
                        .font(.displayItalic(10))
                        .foregroundStyle(theme.textTertiary)
                }
                .padding(.bottom, 12)

                Rectangle()
                    .fill(theme.borderLight)
                    .frame(height: 1)
                    .padding(.bottom, 12)

                HStack {
                    Spacer(minLength: 0)
                    StreakDotsView(sessionDates: sessionDates)
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .cardPaperNoise()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Current streak: \(cachedStreak.current) days. Personal best: \(cachedStreak.longest) days."
        )
    }

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    private static func formatDecimal(_ n: Int) -> String {
        decimalFormatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    private func handleStackCascadeComplete() {
        saveAnimator.cascadeDidComplete()
    }

    private func handleTimerDismiss() {
        triggerSaveAnimation()
    }

    private func handleLogSessionDismiss() {
        triggerSaveAnimation()
    }

    private func triggerSaveAnimation() {
        guard !saveAnimator.isAnimating else { return }
        guard let wordCount = pendingSaveWordCount, wordCount > 0 else {
            holdStackCascade = false
            return
        }
        pendingSaveWordCount = nil

        if saveAudioEngine == nil {
            saveAudioEngine = TypewriterAudioEngine()
        }

        saveAnimator.beginCeremony(
            wordCount: wordCount,
            isFirstToday: isFirstSessionToday,
            onComplete: {
                saveAudioEngine?.shutdown()
                saveAudioEngine = nil
            }
        )

        holdStackCascade = false
    }
}
