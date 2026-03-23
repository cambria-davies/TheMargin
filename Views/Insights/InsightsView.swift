import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.marginTheme) private var theme
    @Query(sort: \Session.date) private var allSessions: [Session]
    @Query(filter: #Predicate<Project> { !$0.isArchived }) private var projects: [Project]
    @State private var selectedProjectID: String?
    @State private var selectedPeriod: InsightsPeriod = .week

    private var filteredSessions: [Session] {
        if let id = selectedProjectID {
            return allSessions.filter { $0.project?.id.uuidString == id }
        }
        return allSessions
    }

    /// Shared computation — avoids recalculating wordsByDay in every content method per body evaluation.
    private var wordsByDay: [Date: Int] {
        InsightsCalculator.wordsByDay(filteredSessions)
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
                    mainTierContent(sessionCount: sessionCount)
                case .full:
                    mainTierContent(sessionCount: nil)
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
                        HStack(spacing: 6) {
                            Text(insightsFilterMenuTitle)
                                .font(.grotesk(12))
                                .foregroundStyle(theme.text)
                                .lineLimit(1)
                            Image(systemName: "arrowtriangle.down.fill")
                                .font(.system(size: 7))
                                .foregroundStyle(theme.text)
                        }
                    }
                }
            }
        }
    }

    /// Uppercase menu label; project name when filtered.
    private var insightsFilterMenuTitle: String {
        if let id = selectedProjectID,
           let name = projects.first(where: { $0.id.uuidString == id })?.name {
            return name.uppercased()
        }
        return "ALL PROJECTS"
    }

    // MARK: - Empty State

    private var emptyTierContent: some View {
        VStack(spacing: 16) {
            Spacer()
            GhostChartView(style: .bars, opacity: 0.08, unlockLabel: nil, ghostColor: theme.text)
                .frame(height: 100).padding(.horizontal, 40)
            Text("\"Start before you're ready.\"")
                .font(.grotesk(14)).italic().foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Text("— Steven Pressfield")
                .font(.grotesk(11)).foregroundStyle(theme.textTertiary)
            Text("Log your first session and your patterns will start to take shape.")
                .font(.grotesk(14)).foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40).padding(.top, 8)
            Spacer()
        }
    }

    private var periodTabs: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach([InsightsPeriod.week, .month, .year], id: \.self) { period in
                    Button {
                        selectedPeriod = period
                    } label: {
                        Text(period.label)
                            .font(.mono(11))
                            .textCase(.uppercase)
                            .tracking(0.12 * 11)
                            .foregroundStyle(
                                selectedPeriod == period ? theme.accent : theme.insightsPeriodTabInactive
                            )
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 6)

            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(theme.borderLight)
                    .frame(height: 1)
                HStack(spacing: 0) {
                    ForEach([InsightsPeriod.week, .month, .year], id: \.self) { period in
                        Rectangle()
                            .fill(selectedPeriod == period ? theme.accent : Color.clear)
                            .frame(height: theme.activeTabIndicatorWidth)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: theme.activeTabIndicatorWidth)
        }
    }

    // MARK: - Main Content

    private func mainTierContent(sessionCount: Int?) -> some View {
        let isLocked = sessionCount != nil

        return ScrollView {
            VStack(spacing: 20) {
                Text("Insights")
                    .font(.displayItalic(20))
                    .foregroundStyle(theme.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                Rectangle()
                    .fill(theme.borderLight)
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                periodTabs
                    .padding(.horizontal, 16)

                // Scope-specific content
                switch selectedPeriod {
                case .week:
                    weekContent(isLocked: isLocked, sessionCount: sessionCount)
                case .month:
                    monthContent(isLocked: isLocked, sessionCount: sessionCount)
                case .year:
                    yearContent(isLocked: isLocked, sessionCount: sessionCount)
                }

                // Shared: Goal Progress
                ForEach(projects.filter { $0.wordCountGoal > 0 }) { project in
                    GoalProgressCardView(project: project).padding(.horizontal, 16)
                }

                Spacer(minLength: 20)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Week Content

    @ViewBuilder
    private func weekContent(isLocked: Bool, sessionCount: Int?) -> some View {
        let periodSessions = InsightsCalculator.filteredByPeriod(filteredSessions, period: .week)

        // Day strip anchor
        DayStripView(wordsByDay: wordsByDay)
            .padding(.horizontal, 16)

        // Streak bar
        let streak = StreakCalculator.calculate(sessionDates: filteredSessions.map(\.date))
        StreakBarView(current: streak.current)
            .padding(.horizontal, 16)

        // Scoped stat cards
        scopedStatCards(sessions: periodSessions, period: .week)

        // Weekly trend chart
        if isLocked, let count = sessionCount {
            lockedChartSection(title: "WORDS PER WEEK", style: .line, sessionCount: count)
                .padding(.horizontal, 16)
        } else {
            let weeklyData = InsightsCalculator.wordsPerWeekTrend(filteredSessions)
            TrendChartView(
                title: "WORDS PER WEEK",
                data: weeklyData.map { (date: $0.weekStart, words: $0.words) },
                periodLabel: "THIS WEEK",
                avgLabel: "AVG / WEEK",
                centerValue: weeklyData.last?.words ?? 0,
                xAxisFormat: .dateTime.month(.abbreviated).day(),
                xAxisStride: .weekOfYear
            )
            .padding(.horizontal, 16)
        }

        // Scoped mood
        MoodDistributionView(distribution: InsightsCalculator.moodDistribution(periodSessions))
            .padding(16)
            .background(theme.surface)
            .overlay {
                CardPaperNoise()
                    .clipShape(Rectangle())
                    .allowsHitTesting(false)
            }
            .clipShape(Rectangle())
            .overlay {
                Rectangle().strokeBorder(theme.border, lineWidth: 1)
            }
            .padding(.horizontal, 16)
    }

    // MARK: - Month Content

    @ViewBuilder
    private func monthContent(isLocked: Bool, sessionCount: Int?) -> some View {
        let periodSessions = InsightsCalculator.filteredByPeriod(filteredSessions, period: .month)

        // Calendar heatmap anchor
        WritingCalendarView(wordsByDay: wordsByDay)
            .padding(.horizontal, 16)

        // Scoped stat cards
        scopedStatCards(sessions: periodSessions, period: .month)

        // Monthly trend chart
        if isLocked, let count = sessionCount {
            lockedChartSection(title: "WORDS PER MONTH", style: .line, sessionCount: count)
                .padding(.horizontal, 16)
        } else {
            let monthlyData = InsightsCalculator.wordsPerMonthTrend(filteredSessions)
            TrendChartView(
                title: "WORDS PER MONTH",
                data: monthlyData.map { (date: $0.monthStart, words: $0.words) },
                periodLabel: "THIS MONTH",
                avgLabel: "AVG / MONTH",
                centerValue: monthlyData.last?.words ?? 0,
                xAxisFormat: .dateTime.month(.abbreviated),
                xAxisStride: .month
            )
            .padding(.horizontal, 16)
        }

        // Day-of-week bar chart
        if isLocked, let count = sessionCount {
            lockedChartSection(title: "WORDS BY DAY OF WEEK", style: .bars, sessionCount: count)
                .padding(.horizontal, 16)
        } else {
            DayOfWeekChartView(
                wordsByDayOfWeek: InsightsCalculator.wordsByDayOfWeek(periodSessions),
                bestDay: InsightsCalculator.bestDayOfWeek(periodSessions)
            )
            .padding(.horizontal, 16)
        }

        // Scoped mood
        MoodDistributionView(distribution: InsightsCalculator.moodDistribution(periodSessions))
            .padding(16)
            .background(theme.surface)
            .overlay {
                CardPaperNoise()
                    .clipShape(Rectangle())
                    .allowsHitTesting(false)
            }
            .clipShape(Rectangle())
            .overlay {
                Rectangle().strokeBorder(theme.border, lineWidth: 1)
            }
            .padding(.horizontal, 16)
    }

    // MARK: - Year Content

    @ViewBuilder
    private func yearContent(isLocked: Bool, sessionCount: Int?) -> some View {
        let periodSessions = InsightsCalculator.filteredByPeriod(filteredSessions, period: .year)

        // Year heatmap anchor
        yearHeatmap
            .padding(.horizontal, 16)

        // Scoped stat cards
        scopedStatCards(sessions: periodSessions, period: .year)

        // Yearly trend chart
        if isLocked, let count = sessionCount {
            lockedChartSection(title: "WORDS PER MONTH", style: .line, sessionCount: count)
                .padding(.horizontal, 16)
        } else {
            let yearData = InsightsCalculator.wordsPerYearTrend(filteredSessions)
            let yearTotal = yearData.map(\.words).reduce(0, +)
            TrendChartView(
                title: "WORDS PER MONTH",
                data: yearData.map { (date: $0.monthStart, words: $0.words) },
                periodLabel: "THIS YEAR",
                avgLabel: "AVG / MONTH",
                centerValue: yearTotal,
                xAxisFormat: .dateTime.month(.abbreviated),
                xAxisStride: .month
            )
            .padding(.horizontal, 16)
        }

        // Milestones (shows regardless of tier, streaks omitted when filtering by project)
        let isFilteredByProject = selectedProjectID != nil
        let milestones = MilestoneCalculator.calculate(
            sessions: isFilteredByProject ? filteredSessions : allSessions.sorted(by: { $0.date < $1.date }),
            projects: isFilteredByProject ? projects.filter { $0.id.uuidString == selectedProjectID } : Array(projects),
            includeStreaks: !isFilteredByProject
        )
        if !milestones.isEmpty {
            MilestonesTimelineView(milestones: milestones)
                .padding(.horizontal, 16)
        }

        // Scoped mood
        MoodDistributionView(distribution: InsightsCalculator.moodDistribution(periodSessions))
            .padding(16)
            .background(theme.surface)
            .overlay {
                CardPaperNoise()
                    .clipShape(Rectangle())
                    .allowsHitTesting(false)
            }
            .clipShape(Rectangle())
            .overlay {
                Rectangle().strokeBorder(theme.border, lineWidth: 1)
            }
            .padding(.horizontal, 16)
    }

    // MARK: - Year Heatmap (inlined)

    @ViewBuilder
    private var yearHeatmap: some View {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: .now)

        if let jan1 = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
           let dec31 = calendar.date(from: DateComponents(year: year, month: 12, day: 31)),
           let daySpan = calendar.dateComponents([.day], from: jan1, to: dec31).day {
            let totalDays = daySpan + 1
            let firstWeekday = calendar.component(.weekday, from: jan1)
            let totalCells = firstWeekday - 1 + totalDays
            let totalColumns = (totalCells + 6) / 7
            let heatmapWordsByDay = wordsByDay
            let maxWords = heatmapWordsByDay.values.max() ?? 1
            let gridSpacing: CGFloat = 2
            let monthLabels = calendar.shortMonthSymbols

            let monthColumns: [Int] = (1...12).map { month in
                guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                      let dayOfYear = calendar.dateComponents([.day], from: jan1, to: monthStart).day else {
                    return 0
                }
                return (firstWeekday - 1 + dayOfYear) / 7
            }

            YearHeatmapLayout(
                totalColumns: totalColumns,
                totalDays: totalDays,
                firstWeekday: firstWeekday,
                gridSpacing: gridSpacing,
                monthLabels: monthLabels,
                monthColumns: monthColumns,
                jan1: jan1,
                wordsByDay: heatmapWordsByDay,
                maxWords: maxWords
            )
        }
    }

    // MARK: - Scoped Stat Cards

    private func sessionsPeriodLabel(_ period: InsightsPeriod) -> String {
        switch period {
        case .week: return "SESSIONS / WK"
        case .month: return "SESSIONS / MO"
        case .year: return "SESSIONS / YR"
        }
    }

    private func scopedStatCards(sessions: [Session], period: InsightsPeriod) -> some View {
        let avgWords = InsightsCalculator.averageWordsPerSession(sessions)
        let avgDuration = InsightsCalculator.averageDurationSeconds(sessions)
        let bestDay = InsightsCalculator.bestDayOfWeek(sessions)
        let sessionCount = sessions.count
        let dayLabels = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date.now)
        /// Highlight “Best day” only when that weekday is today (matches mockup).
        let highlightBestDayCard = bestDay.map { $0 == todayWeekday } ?? false

        let avgWordsFormatted = Self.decimalString(avgWords)

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCardView(label: "AVG / SESSION", value: avgWordsFormatted)
            StatCardView(
                label: "AVG DURATION",
                value: avgDuration.map { "\($0 / 60)m" } ?? "\u{2014}"
            )
            StatCardView(
                label: "BEST DAY",
                value: bestDay.map { dayLabels[$0] } ?? "\u{2014}",
                isHighlighted: highlightBestDayCard
            )
            StatCardView(label: sessionsPeriodLabel(period), value: "\(sessionCount)")
        }
        .padding(.horizontal, 16)
    }

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    private static func decimalString(_ n: Int) -> String {
        decimalFormatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    // MARK: - Locked Chart

    private func lockedChartSection(title: String, style: GhostChartView.Style, sessionCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.mono(9, weight: .semibold))
                .tracking(1)
                .foregroundStyle(theme.textTertiary)
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
        .overlay {
            CardPaperNoise()
                .clipShape(Rectangle())
                .allowsHitTesting(false)
        }
        .clipShape(Rectangle())
        .overlay {
            Rectangle().strokeBorder(theme.border, lineWidth: 1)
        }
    }
}

// MARK: - Year Heatmap Height Preference

private struct HeatmapHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Year Heatmap (self-sizing)

private struct YearHeatmapLayout: View {
    @Environment(\.marginTheme) private var theme
    let totalColumns: Int
    let totalDays: Int
    let firstWeekday: Int
    let gridSpacing: CGFloat
    let monthLabels: [String]
    let monthColumns: [Int]
    let jan1: Date
    let wordsByDay: [Date: Int]
    let maxWords: Int

    @State private var contentHeight: CGFloat = 66

    private let monthLabelHeight: CGFloat = 12
    private let labelGridSpacing: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            let cellSize = max(3, (geo.size.width - CGFloat(totalColumns - 1) * gridSpacing) / CGFloat(totalColumns))
            let gridHeight = 7 * cellSize + 6 * gridSpacing

            VStack(alignment: .leading, spacing: labelGridSpacing) {
                ZStack(alignment: .topLeading) {
                    Color.clear.frame(height: monthLabelHeight)
                    ForEach(0..<12, id: \.self) { i in
                        Text(monthLabels[i])
                            .font(.mono(8))
                            .foregroundStyle(theme.textTertiary)
                            .offset(x: CGFloat(monthColumns[i]) * (cellSize + gridSpacing))
                    }
                }

                let calendar = Calendar.current
                LazyHGrid(rows: Array(repeating: GridItem(.fixed(cellSize), spacing: gridSpacing), count: 7), spacing: gridSpacing) {
                    ForEach(0..<(firstWeekday - 1), id: \.self) { _ in
                        Color.clear.frame(width: cellSize, height: cellSize)
                    }
                    ForEach(0..<totalDays, id: \.self) { index in
                        if let date = calendar.date(byAdding: .day, value: index, to: jan1) {
                            let dayStart = calendar.startOfDay(for: date)
                            let words = wordsByDay[dayStart] ?? 0
                            let intensity = maxWords > 0 ? Double(words) / Double(maxWords) : 0
                            Rectangle()
                                .fill(words > 0 ? theme.accent.opacity(0.2 + intensity * 0.6) : theme.surfaceDark)
                                .frame(width: cellSize, height: cellSize)
                                .accessibilityLabel("\(date.formatted(.dateTime.month(.abbreviated).day())), \(words) words")
                        }
                    }
                }
                .frame(height: gridHeight)
            }
            .background(
                GeometryReader { content in
                    Color.clear.preference(key: HeatmapHeightKey.self, value: content.size.height)
                }
            )
        }
        .frame(height: contentHeight)
        .onPreferenceChange(HeatmapHeightKey.self) { height in
            if height > 0 { contentHeight = height }
        }
    }
}
