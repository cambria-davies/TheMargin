import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.marginTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(filter: #Predicate<Project> { !$0.isArchived },
           sort: \Project.createdAt)
    private var projects: [Project]
    @Query(sort: \Session.date, order: .reverse)
    private var allSessions: [Session]

    @AppStorage("lastUsedProjectID") private var lastUsedProjectID: String = ""
    @State private var showTimerScreen = false
    @State private var showLogSession = false
    @State private var showSettings = false

    // Dashboard open choreography
    @State private var showStats = false
    @State private var showProgress = false
    @State private var showStreak = false
    @State private var showFAB = false
    @State private var progressBarFill: Double = 0

    // Save-to-stack animation
    @State private var saveAnimator = SaveToStackAnimator()
    @State private var saveAudioEngine: TypewriterAudioEngine?
    @State private var pendingSaveWordCount: Int?
    @State private var holdStackCascade = false

    private var currentProject: Project? {
        projects.first(where: { $0.id.uuidString == lastUsedProjectID }) ?? projects.first
    }

    private var streak: StreakResult {
        StreakCalculator.calculate(sessionDates: allSessions.map(\.date))
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
        // After save, there will be 1 session today — that means it was the first
        return todaySessions.count <= 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Manuscript Stack
                        if let project = currentProject {
                            ManuscriptStackView(
                                totalWords: project.totalWords,
                                goalWords: project.wordCountGoal,
                                size: .dashboard,
                                showGlow: true,
                                animated: true,
                                recentSessions: recentSessionSummaries,
                                holdCascade: holdStackCascade
                            )
                            .padding(.top, 16)

                            if saveAnimator.showConfirmation {
                                // Save-to-stack typewriter confirmation
                                TypewriterConfirmation(
                                    text: saveAnimator.confirmationText,
                                    audioEngine: saveAudioEngine
                                )
                                .opacity(saveAnimator.confirmationFadeOut ? 0 : 1)
                                .padding(.top, 4)
                            } else if !project.sessions.isEmpty {
                                Text("Hold to peek")
                                    .font(.literata(10, weight: .medium))
                                    .foregroundStyle(theme.textFaint)
                                    .tracking(1.5)
                            }

                            // Stats
                            HStack(spacing: 32) {
                                VStack(spacing: 2) {
                                    OdometerView(value: project.totalWords, animated: true)
                                    Text("TOTAL")
                                        .font(.literata(10, weight: .medium))
                                        .foregroundStyle(theme.textDim)
                                        .tracking(1.5)
                                }
                                VStack(spacing: 2) {
                                    OdometerView(value: project.wordsToday, animated: true)
                                    Text("TODAY")
                                        .font(.literata(10, weight: .medium))
                                        .foregroundStyle(theme.textDim)
                                        .tracking(1.5)
                                }
                            }
                            .opacity(showStats ? 1 : 0)
                            .offset(y: showStats ? 0 : 10)

                            // Progress bar (if goal set)
                            if project.wordCountGoal > 0 {
                                let progress = project.goalProgress
                                VStack(spacing: 4) {
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(theme.amberDim)
                                            .frame(width: 220, height: 4)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(theme.amber)
                                            .frame(width: 220 * progressBarFill, height: 4)
                                    }

                                    Text("\(Int(progress * 100))%")
                                        .font(.mono(11))
                                        .foregroundStyle(theme.textDim)
                                }
                                .opacity(showProgress ? 1 : 0)
                                .offset(y: showProgress ? 0 : 10)
                                .onChange(of: showProgress) { _, visible in
                                    if visible {
                                        withAnimation(.easeOut(duration: 0.8)) {
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
                                    if newPhase == .pagesLand {
                                        withAnimation(.easeOut(duration: 2.8)) {
                                            progressBarFill = progress
                                        }
                                    }
                                }
                            }
                        } else {
                            ManuscriptStackView.emptyState(size: .dashboard)
                                .padding(.top, 16)
                            Text("Create a project to get started")
                                .font(.literata(14))
                                .foregroundStyle(theme.textDim)
                        }

                        // Streak
                        if let project = currentProject, project.sessions.isEmpty {
                            // Empty state: evocative message
                            VStack(spacing: 8) {
                                Text("The blank page has met its match.")
                                    .font(.literata(14))
                                    .italic()
                                    .foregroundStyle(theme.textDim)
                                Text("Tap the pen to log your first session.")
                                    .font(.literata(11))
                                    .foregroundStyle(theme.textFaint)
                            }
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 44)
                            .opacity(showStreak ? 1 : 0)
                            .offset(y: showStreak ? 0 : 10)
                        } else {
                            // Normal streak counter
                            VStack(spacing: 6) {
                                HStack(spacing: 16) {
                                    VStack(spacing: 2) {
                                        Text("\(streak.current)")
                                            .font(.display(36))
                                            .foregroundStyle(theme.amber)
                                            .scaleEffect(saveAnimator.streakPulse ? 1.15 : 1.0)
                                        Text("day streak")
                                            .font(.literata(10))
                                            .foregroundStyle(theme.textDim)
                                    }
                                    VStack(alignment: .trailing, spacing: 6) {
                                        StreakDotsView(sessionDates: allSessions.map(\.date))
                                        Text("best: \(streak.longest)")
                                            .font(.literata(10))
                                            .italic()
                                            .foregroundStyle(theme.textFaint)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 44)
                            .opacity(showStreak ? 1 : 0)
                            .offset(y: showStreak ? 0 : 10)
                        }

                        Spacer(minLength: 80)
                    }
                }

                // Pen FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        PenFABView(
                            onStartSession: { showTimerScreen = true },
                            onLogSession: { showLogSession = true }
                        )
                        .opacity(showFAB ? 1 : 0)
                        .scaleEffect(showFAB ? 1 : 0)
                    }
                }

                // (save animation: form collapse in LogSessionView, pages land + confirmation on dashboard)
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
                        HStack(spacing: 4) {
                            Text(currentProject?.name.uppercased() ?? "NO PROJECT")
                                .font(.typewriter(13))
                                .foregroundStyle(theme.text)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9))
                                .foregroundStyle(theme.textDim)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(theme.textDim)
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
            .task {
                if reduceMotion {
                    showStats = true
                    showProgress = true
                    showStreak = true
                    showFAB = true
                    progressBarFill = currentProject?.goalProgress ?? 0.0
                    return
                }
                // Choreographed reveal: stack 0-800ms, stats 800ms, progress 900ms,
                // streak 1100ms, dots 1200ms, FAB 1300ms
                try? await Task.sleep(for: .milliseconds(800))
                withAnimation(.timingCurve(0.2, 0, 0.1, 1, duration: 0.5)) {
                    showStats = true
                }
                try? await Task.sleep(for: .milliseconds(100))
                withAnimation(.easeOut(duration: 0.8)) {
                    showProgress = true
                }
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation(.easeOut(duration: 0.2)) {
                    showStreak = true
                }
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    showFAB = true
                }
            }
        }
    }

    // MARK: - Save-to-Stack

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

        // Release the cascade hold — pages animate now that the dashboard is visible
        holdStackCascade = false

        Task {
            await saveAnimator.start(
                wordCount: wordCount,
                isFirstToday: isFirstSessionToday,
                reduceMotion: reduceMotion
            )
            saveAudioEngine?.shutdown()
            saveAudioEngine = nil
        }
    }
}
