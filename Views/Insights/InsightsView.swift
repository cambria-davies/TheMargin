import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.marginTheme) private var theme
    @Query(sort: \Session.date) private var allSessions: [Session]
    @Query(filter: #Predicate<Project> { !$0.isArchived }) private var projects: [Project]
    @State private var selectedProjectID: String?

    private var filteredSessions: [Session] {
        if let id = selectedProjectID {
            return allSessions.filter { $0.project?.id.uuidString == id }
        }
        return allSessions
    }

    private var hasEnoughData: Bool { filteredSessions.count >= 7 }

    var body: some View {
        NavigationStack {
            ScrollView {
                if !hasEnoughData {
                    VStack(spacing: 16) {
                        Spacer(minLength: 80)
                        Text("Log a few more sessions and your patterns will start to emerge.")
                            .font(.literata(14)).foregroundStyle(theme.textDim).multilineTextAlignment(.center).padding(.horizontal, 40)
                        Text("\(filteredSessions.count) of 7 sessions")
                            .font(.mono(12)).foregroundStyle(theme.textFaint)
                    }
                } else {
                    VStack(spacing: 20) {
                        WritingCalendarView(wordsByDay: InsightsCalculator.wordsByDay(filteredSessions)).padding(.horizontal, 16)

                        let avgWords = InsightsCalculator.averageWordsPerSession(filteredSessions)
                        let avgDuration = InsightsCalculator.averageDurationSeconds(filteredSessions)
                        let bestDay = InsightsCalculator.bestDayOfWeek(filteredSessions)
                        let weekTotal = InsightsCalculator.thisWeekTotal(filteredSessions)
                        let dayLabels = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCardView(label: "Avg words/session", value: "\(avgWords)")
                            StatCardView(label: "Avg duration", value: avgDuration.map { "\($0 / 60)m" } ?? "\u{2014}")
                            StatCardView(label: "Best day", value: bestDay.map { dayLabels[$0] } ?? "\u{2014}", isHighlighted: true)
                            StatCardView(label: "This week", value: "\(weekTotal)")
                        }
                        .padding(.horizontal, 16)

                        let streak = StreakCalculator.calculate(sessionDates: filteredSessions.map(\.date))
                        HStack {
                            HStack(spacing: 4) {
                                Text("\(streak.current)").font(.display(20)).foregroundStyle(theme.amber)
                                Text("current streak").font(.literata(12)).foregroundStyle(theme.textDim)
                            }
                            Spacer()
                            Text("longest: \(streak.longest)").font(.literata(12)).italic().foregroundStyle(theme.textFaint)
                        }
                        .padding(.horizontal, 16)

                        DayOfWeekChartView(
                            wordsByDayOfWeek: InsightsCalculator.wordsByDayOfWeek(filteredSessions),
                            bestDay: bestDay
                        ).padding(.horizontal, 16)

                        WeeklyTrendChartView(weeklyData: InsightsCalculator.wordsPerWeekTrend(filteredSessions)).padding(.horizontal, 16)

                        MoodDistributionView(distribution: InsightsCalculator.moodDistribution(filteredSessions))
                            .padding(16).background(theme.surface).clipShape(.rect(cornerRadius: 12)).padding(.horizontal, 16)

                        ForEach(projects.filter { $0.wordCountGoal != nil }) { project in
                            GoalProgressCardView(project: project).padding(.horizontal, 16)
                        }
                        Spacer(minLength: 20)
                    }
                    .padding(.top, 8)
                }
            }
            .background(theme.background)
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All Projects") { selectedProjectID = nil }
                        ForEach(projects) { project in
                            Button(project.name) { selectedProjectID = project.id.uuidString }
                        }
                    } label: {
                        Text(selectedProjectID == nil ? "All Projects" : "Filtered")
                            .font(.literata(12)).foregroundStyle(theme.amber)
                        Image(systemName: "chevron.down").font(.system(size: 9))
                    }
                }
            }
        }
    }
}
