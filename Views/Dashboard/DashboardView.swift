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
    @State private var showProjectPicker = false
    @State private var showTimerScreen = false
    @State private var showLogSession = false
    @State private var showSettings = false

    // Dashboard open choreography
    @State private var showStats = false
    @State private var showProgress = false
    @State private var showStreak = false
    @State private var showFAB = false

    private var currentProject: Project? {
        projects.first(where: { $0.id.uuidString == lastUsedProjectID }) ?? projects.first
    }

    private var streak: StreakResult {
        StreakCalculator.calculate(sessionDates: allSessions.map(\.date))
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
                                animated: true
                            )
                            .padding(.top, 16)

                            Text("Hold to peek")
                                .font(.literata(10, weight: .medium))
                                .foregroundStyle(theme.textFaint)
                                .tracking(1.5)

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
                            if let progress = project.goalProgress {
                                VStack(spacing: 4) {
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(theme.surfaceRaised)
                                            .frame(width: 220, height: 4)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(theme.amber)
                                            .frame(width: 220 * progress, height: 4)
                                    }

                                    Text("\(Int(progress * 100))%")
                                        .font(.mono(11))
                                        .foregroundStyle(theme.textDim)
                                }
                                .opacity(showProgress ? 1 : 0)
                                .offset(y: showProgress ? 0 : 10)
                            }
                        } else {
                            ManuscriptStackView.emptyState(size: .dashboard)
                                .padding(.top, 16)
                            Text("Create a project to get started")
                                .font(.literata(14))
                                .foregroundStyle(theme.textDim)
                        }

                        // Streak
                        HStack {
                            HStack(spacing: 4) {
                                Text("\(streak.current)")
                                    .font(.display(22))
                                    .foregroundStyle(theme.amber)
                                Text("day streak")
                                    .font(.literata(12))
                                    .foregroundStyle(theme.textDim)
                            }
                            Spacer()
                            StreakDotsView(sessionDates: allSessions.map(\.date))
                        }
                        .padding(.horizontal, 24)
                        .opacity(showStreak ? 1 : 0)
                        .offset(y: showStreak ? 0 : 10)

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
                        .scaleEffect(showFAB ? 1 : 0.8)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showProjectPicker = true
                    } label: {
                        Text(currentProject?.name.uppercased() ?? "NO PROJECT")
                            .font(.typewriter(13))
                            .foregroundStyle(theme.text)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                            .foregroundStyle(theme.textDim)
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
            .confirmationDialog("Select Project", isPresented: $showProjectPicker) {
                ForEach(projects) { project in
                    Button(project.name) {
                        lastUsedProjectID = project.id.uuidString
                    }
                }
            }
            .fullScreenCover(isPresented: $showTimerScreen) {
                TimerView()
            }
            .sheet(isPresented: $showLogSession) {
                LogSessionView()
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
                    return
                }
                // Choreographed reveal sequence
                try? await Task.sleep(for: .milliseconds(800))
                withAnimation(.easeOut(duration: 0.4)) {
                    showStats = true
                }
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation(.easeOut(duration: 0.4)) {
                    showProgress = true
                }
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation(.easeOut(duration: 0.4)) {
                    showStreak = true
                }
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showFAB = true
                }
            }
        }
    }
}
