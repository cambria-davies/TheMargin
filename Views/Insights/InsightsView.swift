import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.marginTheme) private var theme
    @Query(sort: \Session.date) private var allSessions: [Session]
    @Query(filter: #Predicate<Project> { !$0.isArchived }) private var projects: [Project]
    @Query private var tips: [WritingTip]
    @State private var selectedProjectID: String?
    @State private var currentTip: WritingTip?

    private var filteredSessions: [Session] {
        if let id = selectedProjectID {
            return allSessions.filter { $0.project?.id.uuidString == id }
        }
        return allSessions
    }

    var body: some View {
        NavigationStack {
            Group {
                let sessionCount = filteredSessions.count
                let tier = InsightsTier.forSessionCount(sessionCount)

                switch tier {
                case .empty:
                    emptyTierContent
                case .partial:
                    partialTierContent(sessionCount: sessionCount)
                case .full:
                    fullTierContent
                }
            }
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
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
        .task {
            if currentTip == nil {
                let service = TipRotationService(tips: tips)
                currentTip = service.tipForToday()
            }
        }
    }

    // MARK: - Tier 1: Empty (0 sessions)

    private var emptyTierContent: some View {
        VStack(spacing: 16) {
            Spacer()

            GhostChartView(
                style: .bars,
                opacity: 0.08,
                unlockLabel: nil,
                ghostColor: theme.text
            )
            .frame(height: 100)
            .padding(.horizontal, 40)

            if let tip = currentTip {
                Text("\"\(tip.text)\"")
                    .font(.literata(14))
                    .italic()
                    .foregroundStyle(theme.textDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if let attribution = tip.attribution {
                    Text("— \(attribution)")
                        .font(.literata(11))
                        .foregroundStyle(theme.textFaint)
                }
            }

            Text("Log your first session and your patterns will start to take shape.")
                .font(.literata(14))
                .foregroundStyle(theme.textDim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Tier 2: Partial (1–6 sessions)

    private func partialTierContent(sessionCount: Int) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Insights")
                    .font(.display(20))
                    .foregroundStyle(theme.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                // UNLOCKED: Calendar
                WritingCalendarView(wordsByDay: InsightsCalculator.wordsByDay(filteredSessions))
                    .padding(.horizontal, 16)

                // UNLOCKED: Stat cards
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

                // UNLOCKED: Streak summary
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

                // LOCKED: Words by day of week
                lockedChartSection(
                    title: "WORDS BY DAY OF WEEK",
                    style: .bars,
                    sessionCount: sessionCount
                )
                .padding(.horizontal, 16)

                // LOCKED: Words per week
                lockedChartSection(
                    title: "WORDS PER WEEK",
                    style: .line,
                    sessionCount: sessionCount
                )
                .padding(.horizontal, 16)

                // UNLOCKED: Mood distribution
                MoodDistributionView(distribution: InsightsCalculator.moodDistribution(filteredSessions))
                    .padding(16)
                    .background(theme.surface)
                    .clipShape(.rect(cornerRadius: 12))
                    .padding(.horizontal, 16)

                // UNLOCKED: Goal progress
                ForEach(projects.filter { $0.wordCountGoal > 0 }) { project in
                    GoalProgressCardView(project: project).padding(.horizontal, 16)
                }

                Spacer(minLength: 20)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Tier 3: Full (7+ sessions)

    private var fullTierContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Insights")
                    .font(.display(20))
                    .foregroundStyle(theme.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                WritingCalendarView(wordsByDay: InsightsCalculator.wordsByDay(filteredSessions))
                    .padding(.horizontal, 16)

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

                WeeklyTrendChartView(weeklyData: InsightsCalculator.wordsPerWeekTrend(filteredSessions))
                    .padding(.horizontal, 16)

                MoodDistributionView(distribution: InsightsCalculator.moodDistribution(filteredSessions))
                    .padding(16)
                    .background(theme.surface)
                    .clipShape(.rect(cornerRadius: 12))
                    .padding(.horizontal, 16)

                ForEach(projects.filter { $0.wordCountGoal > 0 }) { project in
                    GoalProgressCardView(project: project).padding(.horizontal, 16)
                }

                Spacer(minLength: 20)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Locked Chart Section

    private func lockedChartSection(
        title: String,
        style: GhostChartView.Style,
        sessionCount: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.literata(9, weight: .medium))
                .tracking(1)
                .foregroundStyle(theme.textFaint)

            GhostChartView(
                style: style,
                opacity: 0.06,
                unlockLabel: InsightsTier.unlockLabel(currentCount: sessionCount),
                ghostColor: theme.text
            )
            .frame(height: 80)
        }
        .padding(16)
        .background(theme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }
}
