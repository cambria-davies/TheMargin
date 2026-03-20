import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.marginTheme) private var theme
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
                                showGlow: true
                            )
                            .padding(.top, 16)

                            Text("Hold to peek")
                                .font(.literata(10, weight: .medium))
                                .foregroundStyle(theme.textFaint)
                                .tracking(1.5)

                            // Stats
                            HStack(spacing: 32) {
                                VStack(spacing: 2) {
                                    Text("\(project.totalWords)")
                                        .font(.display(28))
                                        .foregroundStyle(theme.text)
                                    Text("TOTAL")
                                        .font(.literata(10, weight: .medium))
                                        .foregroundStyle(theme.textDim)
                                        .tracking(1.5)
                                }
                                VStack(spacing: 2) {
                                    Text("\(project.wordsToday)")
                                        .font(.display(28))
                                        .foregroundStyle(theme.text)
                                    Text("TODAY")
                                        .font(.literata(10, weight: .medium))
                                        .foregroundStyle(theme.textDim)
                                        .tracking(1.5)
                                }
                            }

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
                            Text("best: \(streak.longest)")
                                .font(.literata(12))
                                .italic()
                                .foregroundStyle(theme.textFaint)
                        }
                        .padding(.horizontal, 24)

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
                Text("Timer — Task 12")
            }
            .sheet(isPresented: $showLogSession) {
                Text("Log Session — Task 11")
            }
            .sheet(isPresented: $showSettings) {
                Text("Settings — Task 15")
            }
        }
    }
}
