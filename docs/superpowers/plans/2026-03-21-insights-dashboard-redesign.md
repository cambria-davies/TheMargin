# Insights Dashboard Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Insights tab so Week/Month/Year each tell a scope-appropriate story, eliminating redundancy and adding milestones.

**Architecture:** Refactor InsightsView to render scope-specific layouts instead of one shared layout. Add new InsightsCalculator methods for monthly/yearly trend data and session counting. Create MilestoneCalculator as a new pure-logic service. Extract DayStripView as a new component. Generalize WeeklyTrendChartView into TrendChartView that accepts any time-scale data.

**Tech Stack:** Swift, SwiftUI, SwiftData, Swift Charts, XCTest

**Spec:** `docs/superpowers/specs/2026-03-21-insights-dashboard-redesign.md`

---

## File Map

### New Files
| File | Responsibility |
|---|---|
| `Services/MilestoneCalculator.swift` | Pure-logic service: scans sessions/projects to produce `[Milestone]` |
| `Models/Milestone.swift` | `Milestone` struct and `MilestoneKind` enum |
| `Components/DayStripView.swift` | Week view anchor: 7 cells showing daily word counts |
| `Views/Insights/MilestonesTimelineView.swift` | Year view milestone timeline UI |
| `Views/Insights/TrendChartView.swift` | Generalized trend chart (replaces WeeklyTrendChartView) |
| `TheMarginTests/ServiceTests/MilestoneCalculatorTests.swift` | Tests for milestone detection |

### Modified Files
| File | Changes |
|---|---|
| `Services/InsightsCalculator.swift` | Add `wordsPerMonthTrend`, `sessionCount`, `wordsForCurrentPeriod` methods |
| `Views/Insights/InsightsView.swift` | Rewrite to render scope-specific layouts for Week/Month/Year |
| `Views/Insights/WritingCalendarView.swift` | Remove period picker + week/year views (they move to InsightsView) |
| `TheMarginTests/ServiceTests/InsightsCalculatorTests.swift` | Add tests for new methods |

### Deleted Files
| File | Reason |
|---|---|
| `Views/Insights/WeeklyTrendChartView.swift` | Replaced by generalized `TrendChartView` |

---

## Task 1: Add Milestone Model

**Files:**
- Create: `Models/Milestone.swift`

- [ ] **Step 1: Create Milestone.swift**

```swift
import Foundation

enum MilestoneKind: Equatable {
    case firstSession
    case streakRecord(days: Int)
    case goalReached(projectName: String, goal: Int)
    case mostProductiveDay(words: Int)
    case biggestSession(words: Int)
}

struct Milestone: Equatable {
    let date: Date
    let kind: MilestoneKind

    var description: String {
        switch kind {
        case .firstSession:
            return "First session logged"
        case .streakRecord(let days):
            return "Longest streak: \(days) days"
        case .goalReached(let name, _):
            return "\(name) goal reached"
        case .mostProductiveDay:
            return "Most productive day"
        case .biggestSession:
            return "Biggest session"
        }
    }

    var highlightValue: String {
        switch kind {
        case .firstSession:
            return ""
        case .streakRecord(let days):
            return "\(days) days"
        case .goalReached(_, let goal):
            return "\(goal.formatted()) words"
        case .mostProductiveDay(let words):
            return "\(words.formatted()) words"
        case .biggestSession(let words):
            return "\(words.formatted()) words"
        }
    }
}
```

- [ ] **Step 2: Run xcodegen and build**

```bash
xcodegen generate
xcodebuild -target TheMargin -sdk iphonesimulator build ONLY_ACTIVE_ARCH=YES ARCHS=arm64 --quiet
```

- [ ] **Step 3: Commit**

```bash
git add Models/Milestone.swift
git commit -m "Add Milestone model and MilestoneKind enum"
```

---

## Task 2: Add MilestoneCalculator Service with Tests (TDD)

**Files:**
- Create: `Services/MilestoneCalculator.swift`
- Create: `TheMarginTests/ServiceTests/MilestoneCalculatorTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
import XCTest
@testable import TheMargin

final class MilestoneCalculatorTests: XCTestCase {
    private let calendar = Calendar.current

    private func makeProject(name: String, goal: Int = 0) -> Project {
        Project(name: name, wordCountGoal: goal)
    }

    private func makeSession(
        project: Project,
        daysAgo: Int,
        wordCount: Int,
        mood: Mood = .steady
    ) -> Session {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date.now)!
        return Session(project: project, date: date, wordCount: wordCount, mood: mood)
    }

    // MARK: - First session

    func testFirstSessionMilestone() {
        let project = makeProject(name: "Novel")
        let sessions = [makeSession(project: project, daysAgo: 10, wordCount: 500)]
        let milestones = MilestoneCalculator.calculate(sessions: sessions, projects: [project])
        XCTAssertTrue(milestones.contains { $0.kind == .firstSession })
    }

    func testEmptySessionsProducesNoMilestones() {
        let milestones = MilestoneCalculator.calculate(sessions: [], projects: [])
        XCTAssertTrue(milestones.isEmpty)
    }

    // MARK: - Streak records

    func testStreakRecordEmittedWhenMaxIncreases() {
        let project = makeProject(name: "Novel")
        // 3-day streak then gap then 5-day streak
        let sessions = [
            makeSession(project: project, daysAgo: 20, wordCount: 100),
            makeSession(project: project, daysAgo: 19, wordCount: 100),
            makeSession(project: project, daysAgo: 18, wordCount: 100),
            // gap at daysAgo 17-11
            makeSession(project: project, daysAgo: 10, wordCount: 100),
            makeSession(project: project, daysAgo: 9, wordCount: 100),
            makeSession(project: project, daysAgo: 8, wordCount: 100),
            makeSession(project: project, daysAgo: 7, wordCount: 100),
            makeSession(project: project, daysAgo: 6, wordCount: 100),
        ]
        let milestones = MilestoneCalculator.calculate(sessions: sessions, projects: [project])
        let streakMilestones = milestones.filter {
            if case .streakRecord = $0.kind { return true }; return false
        }
        // First streak of 3 emits a record (skips 1), then 5 breaks it
        XCTAssertEqual(streakMilestones.count, 2)
        XCTAssertTrue(streakMilestones.contains { $0.kind == .streakRecord(days: 3) })
        XCTAssertTrue(streakMilestones.contains { $0.kind == .streakRecord(days: 5) })
    }

    func testSingleDayStreakDoesNotEmitMilestone() {
        let project = makeProject(name: "Novel")
        let sessions = [makeSession(project: project, daysAgo: 5, wordCount: 500)]
        let milestones = MilestoneCalculator.calculate(sessions: sessions, projects: [project])
        let streakMilestones = milestones.filter {
            if case .streakRecord = $0.kind { return true }; return false
        }
        XCTAssertTrue(streakMilestones.isEmpty)
    }

    // MARK: - Goal reached

    func testGoalReachedMilestone() {
        let project = makeProject(name: "Novel", goal: 1000)
        let sessions = [
            makeSession(project: project, daysAgo: 3, wordCount: 600),
            makeSession(project: project, daysAgo: 2, wordCount: 500),
        ]
        project.sessions = sessions
        let milestones = MilestoneCalculator.calculate(sessions: sessions, projects: [project])
        XCTAssertTrue(milestones.contains { $0.kind == .goalReached(projectName: "Novel", goal: 1000) })
    }

    func testGoalNotReachedProducesNoMilestone() {
        let project = makeProject(name: "Novel", goal: 10000)
        let sessions = [makeSession(project: project, daysAgo: 1, wordCount: 500)]
        project.sessions = sessions
        let milestones = MilestoneCalculator.calculate(sessions: sessions, projects: [project])
        XCTAssertFalse(milestones.contains {
            if case .goalReached = $0.kind { return true }; return false
        })
    }

    // MARK: - Biggest session & most productive day

    func testBiggestSessionMilestone() {
        let project = makeProject(name: "Novel")
        let sessions = [
            makeSession(project: project, daysAgo: 3, wordCount: 500),
            makeSession(project: project, daysAgo: 2, wordCount: 2000),
            makeSession(project: project, daysAgo: 1, wordCount: 800),
        ]
        let milestones = MilestoneCalculator.calculate(sessions: sessions, projects: [project])
        XCTAssertTrue(milestones.contains { $0.kind == .biggestSession(words: 2000) })
    }

    func testMostProductiveDayMilestone() {
        let project = makeProject(name: "Novel")
        // Two sessions on the same day = 1500 total for that day
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date.now)!
        let s1 = Session(project: project, date: twoDaysAgo, wordCount: 800, mood: .flow)
        let s2 = Session(project: project, date: twoDaysAgo, wordCount: 700, mood: .flow)
        let s3 = makeSession(project: project, daysAgo: 1, wordCount: 1000)
        let milestones = MilestoneCalculator.calculate(sessions: [s1, s2, s3], projects: [project])
        XCTAssertTrue(milestones.contains { $0.kind == .mostProductiveDay(words: 1500) })
    }

    // MARK: - Project filter suppresses streaks

    func testIncludeStreaksFalseOmitsStreakMilestones() {
        let project = makeProject(name: "Novel")
        let sessions = [
            makeSession(project: project, daysAgo: 3, wordCount: 100),
            makeSession(project: project, daysAgo: 2, wordCount: 100),
            makeSession(project: project, daysAgo: 1, wordCount: 100),
        ]
        let milestones = MilestoneCalculator.calculate(sessions: sessions, projects: [project], includeStreaks: false)
        let streakMilestones = milestones.filter {
            if case .streakRecord = $0.kind { return true }; return false
        }
        XCTAssertTrue(streakMilestones.isEmpty)
    }

    // MARK: - Sorting

    func testMilestonesAreSortedNewestFirst() {
        let project = makeProject(name: "Novel")
        let sessions = [
            makeSession(project: project, daysAgo: 10, wordCount: 500),
            makeSession(project: project, daysAgo: 1, wordCount: 2000),
        ]
        let milestones = MilestoneCalculator.calculate(sessions: sessions, projects: [project])
        // Newest first
        for i in 0..<(milestones.count - 1) {
            XCTAssertGreaterThanOrEqual(milestones[i].date, milestones[i + 1].date)
        }
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodegen generate
xcodebuild test -scheme TheMargin -destination 'platform=iOS Simulator,name=iPhone 16' --quiet 2>&1 | tail -20
```

Expected: Compilation failure — `MilestoneCalculator` not defined.

- [ ] **Step 3: Implement MilestoneCalculator**

```swift
import Foundation

enum MilestoneCalculator {
    static func calculate(sessions: [Session], projects: [Project], includeStreaks: Bool = true) -> [Milestone] {
        guard !sessions.isEmpty else { return [] }

        let sorted = sessions.sorted { $0.date < $1.date }
        var milestones: [Milestone] = []
        let calendar = Calendar.current

        // First session
        milestones.append(Milestone(date: sorted[0].date, kind: .firstSession))

        // Streak records — replay day-by-day chronologically (skip when filtering by project)
        let uniqueDays = Set(sorted.map { calendar.startOfDay(for: $0.date) }).sorted()
        if includeStreaks {
            var currentStreak = 1
            var maxStreak = 1
            for i in 1..<uniqueDays.count {
                let expected = calendar.date(byAdding: .day, value: 1, to: uniqueDays[i - 1])!
                if calendar.isDate(uniqueDays[i], inSameDayAs: expected) {
                    currentStreak += 1
                    if currentStreak > maxStreak {
                        maxStreak = currentStreak
                        milestones.append(Milestone(date: uniqueDays[i], kind: .streakRecord(days: maxStreak)))
                    }
                } else {
                    currentStreak = 1
                }
            }
        }

        // Goal reached — scan sessions chronologically per project
        for project in projects where project.wordCountGoal > 0 {
            let projectSessions = sorted.filter { $0.project?.id == project.id }
            var cumulative = project.startingWordCount
            for session in projectSessions {
                let wasBelowGoal = cumulative < project.wordCountGoal
                cumulative += session.wordCount
                if wasBelowGoal && cumulative >= project.wordCountGoal {
                    milestones.append(Milestone(
                        date: session.date,
                        kind: .goalReached(projectName: project.name, goal: project.wordCountGoal)
                    ))
                    break
                }
            }
        }

        // Biggest session — earliest date wins ties
        if let biggest = sorted.max(by: {
            $0.wordCount < $1.wordCount || ($0.wordCount == $1.wordCount && $0.date > $1.date)
        }) {
            milestones.append(Milestone(date: biggest.date, kind: .biggestSession(words: biggest.wordCount)))
        }

        // Most productive day — sum words per day, earliest date wins ties
        var wordsByDay: [Date: Int] = [:]
        for session in sorted {
            let day = calendar.startOfDay(for: session.date)
            wordsByDay[day, default: 0] += session.wordCount
        }
        if let (day, words) = wordsByDay.max(by: {
            $0.value < $1.value || ($0.value == $1.value && $0.key > $1.key)
        }) {
            milestones.append(Milestone(date: day, kind: .mostProductiveDay(words: words)))
        }

        // Sort newest first
        milestones.sort { $0.date > $1.date }
        return milestones
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodegen generate
xcodebuild test -scheme TheMargin -destination 'platform=iOS Simulator,name=iPhone 16' --quiet 2>&1 | tail -20
```

Expected: All MilestoneCalculatorTests pass.

- [ ] **Step 5: Commit**

```bash
git add Services/MilestoneCalculator.swift TheMarginTests/ServiceTests/MilestoneCalculatorTests.swift
git commit -m "Add MilestoneCalculator service with tests"
```

---

## Task 3: Add InsightsCalculator Methods for Monthly/Yearly Trends and Session Counts (TDD)

**Files:**
- Modify: `Services/InsightsCalculator.swift`
- Modify: `TheMarginTests/ServiceTests/InsightsCalculatorTests.swift`

- [ ] **Step 1: Write failing tests**

Add to `InsightsCalculatorTests.swift`:

```swift
func testWordsPerMonthTrend() {
    // Sessions in different months
    let sessions = [
        makeSession(daysAgo: 60, wordCount: 500),
        makeSession(daysAgo: 30, wordCount: 800),
        makeSession(daysAgo: 1, wordCount: 1200),
    ]
    let trend = InsightsCalculator.wordsPerMonthTrend(sessions, months: 3)
    XCTAssertEqual(trend.count, 3)
    // Each entry has a monthStart and words
    XCTAssertTrue(trend.allSatisfy { $0.words >= 0 })
}

func testWordsPerMonthTrendCapsAt24() {
    let sessions = [makeSession(daysAgo: 0, wordCount: 500)]
    let trend = InsightsCalculator.wordsPerMonthTrend(sessions, months: 30)
    // Capped at 24 even when explicitly requesting more
    XCTAssertLessThanOrEqual(trend.count, 24)
}

func testWordsPerMonthTrendAutoDetectsRange() {
    let sessions = [
        makeSession(daysAgo: 60, wordCount: 500),
        makeSession(daysAgo: 0, wordCount: 300),
    ]
    let trend = InsightsCalculator.wordsPerMonthTrend(sessions)
    // Should auto-detect ~3 months from first session to now
    XCTAssertGreaterThanOrEqual(trend.count, 2)
    XCTAssertLessThanOrEqual(trend.count, 24)
}

func testWordsForCurrentYear() {
    let trend = InsightsCalculator.wordsPerYearTrend([
        makeSession(daysAgo: 1, wordCount: 1000),
    ])
    XCTAssertEqual(trend.count, 12) // Always 12 months for current year
}

func testSessionCount() {
    let sessions = [
        makeSession(daysAgo: 0, wordCount: 500),
        makeSession(daysAgo: 1, wordCount: 800),
        makeSession(daysAgo: 10, wordCount: 300),
    ]
    // This week should have the first two (daysAgo 0 and 1, assuming run within 7 days)
    let weekCount = InsightsCalculator.sessionCount(sessions, period: .week)
    XCTAssertGreaterThanOrEqual(weekCount, 1) // At least today's session
}

func testThisMonthTotal() {
    let sessions = [
        makeSession(daysAgo: 0, wordCount: 500),
        makeSession(daysAgo: 60, wordCount: 9999),
    ]
    let total = InsightsCalculator.periodTotal(sessions, period: .month)
    XCTAssertEqual(total, 500) // Only this month
}

func testThisYearTotal() {
    let sessions = [
        makeSession(daysAgo: 0, wordCount: 500),
        makeSession(daysAgo: 1, wordCount: 300),
    ]
    let total = InsightsCalculator.periodTotal(sessions, period: .year)
    XCTAssertEqual(total, 800)
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -scheme TheMargin -destination 'platform=iOS Simulator,name=iPhone 16' --quiet 2>&1 | tail -20
```

- [ ] **Step 3: Implement new methods**

Add to `InsightsCalculator.swift`:

```swift
enum InsightsPeriod {
    case week, month, year
}

// Add these static methods to the InsightsCalculator enum:

static func wordsPerMonthTrend(_ sessions: [Session], months: Int? = nil) -> [(monthStart: Date, words: Int)] {
    let calendar = Calendar.current
    let today = Date.now

    // Auto-detect range from first session, capped at 24
    let monthCount: Int
    if let months = months {
        monthCount = min(months, 24)
    } else if let earliest = sessions.min(by: { $0.date < $1.date })?.date {
        let comps = calendar.dateComponents([.month], from: earliest, to: today)
        monthCount = min((comps.month ?? 0) + 1, 24)
    } else {
        monthCount = 1
    }

    var result: [(monthStart: Date, words: Int)] = []

    for monthsAgo in (0..<monthCount).reversed() {
        let monthDate = calendar.date(byAdding: .month, value: -monthsAgo, to: today)!
        let comps = calendar.dateComponents([.year, .month], from: monthDate)
        let monthStart = calendar.date(from: comps)!
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        let monthWords = sessions
            .filter { $0.date >= monthStart && $0.date < nextMonth }
            .reduce(0) { $0 + $1.wordCount }
        result.append((monthStart: monthStart, words: monthWords))
    }
    return result
}

static func wordsPerYearTrend(_ sessions: [Session]) -> [(monthStart: Date, words: Int)] {
    let calendar = Calendar.current
    let year = calendar.component(.year, from: Date.now)
    var result: [(monthStart: Date, words: Int)] = []

    for month in 1...12 {
        let comps = DateComponents(year: year, month: month)
        let monthStart = calendar.date(from: comps)!
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        let monthWords = sessions
            .filter { $0.date >= monthStart && $0.date < nextMonth }
            .reduce(0) { $0 + $1.wordCount }
        result.append((monthStart: monthStart, words: monthWords))
    }
    return result
}

static func sessionCount(_ sessions: [Session], period: InsightsPeriod) -> Int {
    filteredByPeriod(sessions, period: period).count
}

static func periodTotal(_ sessions: [Session], period: InsightsPeriod) -> Int {
    filteredByPeriod(sessions, period: period).reduce(0) { $0 + $1.wordCount }
}

static func filteredByPeriod(_ sessions: [Session], period: InsightsPeriod) -> [Session] {
    let calendar = Calendar.current
    let now = Date.now
    let start: Date
    switch period {
    case .week:
        start = calendar.startOfWeek(for: now)
    case .month:
        let comps = calendar.dateComponents([.year, .month], from: now)
        start = calendar.date(from: comps)!
    case .year:
        let comps = calendar.dateComponents([.year], from: now)
        start = calendar.date(from: comps)!
    }
    return sessions.filter { $0.date >= start }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -scheme TheMargin -destination 'platform=iOS Simulator,name=iPhone 16' --quiet 2>&1 | tail -20
```

- [ ] **Step 5: Commit**

```bash
git add Services/InsightsCalculator.swift TheMarginTests/ServiceTests/InsightsCalculatorTests.swift
git commit -m "Add monthly/yearly trend and period-scoped methods to InsightsCalculator"
```

---

## Task 4: Create DayStripView Component

**Files:**
- Create: `Components/DayStripView.swift`

- [ ] **Step 1: Create DayStripView**

```swift
import SwiftUI

struct DayStripView: View {
    let wordsByDay: [Date: Int]
    @Environment(\.marginTheme) private var theme

    private let calendar = Calendar.current
    private let dayInitials = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        let today = calendar.startOfDay(for: .now)
        let weekStart = calendar.startOfWeek(for: today)
        let days = (0..<7).map { offset -> (date: Date, words: Int) in
            let date = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            let dayStart = calendar.startOfDay(for: date)
            return (date: dayStart, words: wordsByDay[dayStart] ?? 0)
        }
        let maxWords = days.map(\.words).max() ?? 1

        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { index in
                let day = days[index]
                let isToday = calendar.isDate(day.date, inSameDayAs: today)
                let intensity = day.words > 0 && maxWords > 0
                    ? max(0.2, min(1.0, Double(day.words) / Double(maxWords)))
                    : 0

                VStack(spacing: 4) {
                    Text(dayInitials[index])
                        .font(.literata(11))
                        .foregroundStyle(isToday ? theme.amber : theme.textFaint)
                    Text(day.words > 9999 ? formatCompact(day.words) : "\(day.words)")
                        .font(.mono(14))
                        .foregroundStyle(day.words > 0 ? (intensity > 0.8 ? theme.background : theme.amber) : theme.textFaint)
                        .opacity(day.words > 0 ? 1.0 : 0.35)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(day.words > 0 ? theme.amber.opacity(intensity) : theme.surfaceRaised)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isToday ? theme.amber : .clear, lineWidth: 2)
                )
            }
        }
    }

    private func formatCompact(_ value: Int) -> String {
        if value >= 10000 {
            let k = Double(value) / 1000.0
            return String(format: "%.1fk", k)
        }
        return "\(value)"
    }
}
```

- [ ] **Step 2: Run xcodegen and build**

```bash
xcodegen generate
xcodebuild -target TheMargin -sdk iphonesimulator build ONLY_ACTIVE_ARCH=YES ARCHS=arm64 --quiet
```

- [ ] **Step 3: Commit**

```bash
git add Components/DayStripView.swift
git commit -m "Add DayStripView component for Week view anchor"
```

---

## Task 5: Create Generalized TrendChartView

This replaces `WeeklyTrendChartView` with a version that accepts any time-scale data.

**Files:**
- Create: `Views/Insights/TrendChartView.swift`
- Delete: `Views/Insights/WeeklyTrendChartView.swift` (after new view is wired in)

- [ ] **Step 1: Create TrendChartView**

```swift
import SwiftUI
import Charts

struct TrendChartView: View {
    let data: [(date: Date, words: Int)]
    let periodLabel: String      // "THIS WEEK", "THIS MONTH", "THIS YEAR"
    let avgLabel: String         // "AVG / WEEK", "AVG / MONTH"
    let centerValue: Int         // Explicit center stat — last data point for week/month, sum for year
    let xAxisFormat: Date.FormatStyle // Controls how x-axis labels render
    let xAxisStride: Calendar.Component // .weekOfYear, .month

    @Environment(\.marginTheme) private var theme

    private var average: Int {
        guard !data.isEmpty else { return 0 }
        return data.map(\.words).reduce(0, +) / data.count
    }

    private var percentVsAverage: Int? {
        guard average > 0 else { return nil }
        return Int(((Double(centerValue) / Double(average)) - 1.0) * 100)
    }

    var body: some View {
        VStack(spacing: 8) {
            Chart {
                ForEach(data, id: \.date) { entry in
                    LineMark(x: .value("Period", entry.date), y: .value("Words", entry.words))
                        .foregroundStyle(theme.amber)
                        .interpolationMethod(.catmullRom)
                    AreaMark(x: .value("Period", entry.date), y: .value("Words", entry.words))
                        .foregroundStyle(theme.amber.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    if entry.date == data.last?.date {
                        PointMark(x: .value("Period", entry.date), y: .value("Words", entry.words))
                            .foregroundStyle(theme.amber)
                            .symbolSize(40)
                            .annotation(position: .top) {
                                Text("\(entry.words)").font(.mono(8)).foregroundStyle(theme.amber)
                            }
                    }
                    if entry.date == data.first?.date {
                        PointMark(x: .value("Period", entry.date), y: .value("Words", entry.words))
                            .foregroundStyle(theme.textFaint)
                            .symbolSize(20)
                            .annotation(position: .top) {
                                Text("\(entry.words)").font(.mono(7)).foregroundStyle(theme.textFaint)
                            }
                    }
                }
                RuleMark(y: .value("Average", average))
                    .foregroundStyle(theme.textFaint)
                    .lineStyle(StrokeStyle(dash: [4, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("avg \(average)").font(.mono(8)).foregroundStyle(theme.textFaint)
                    }
            }
            .frame(height: 140)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: xAxisStride)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: xAxisFormat)
                        .font(.literata(8)).foregroundStyle(theme.textFaint)
                }
            }

            HStack {
                if let pct = percentVsAverage {
                    Text(pct >= 0 ? "+\(pct)%" : "\(pct)%")
                        .font(.display(16))
                        .foregroundStyle(pct >= 0 ? Color(hex: 0x7A9070) : Color(hex: 0x7A5C50))
                    Text("vs avg").font(.literata(8)).foregroundStyle(theme.textFaint).textCase(.uppercase)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(centerValue)").font(.display(16)).foregroundStyle(theme.text)
                    Text(periodLabel).font(.literata(8)).foregroundStyle(theme.textFaint).tracking(0.5)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(average)").font(.display(16)).foregroundStyle(theme.text)
                    Text(avgLabel).font(.literata(8)).foregroundStyle(theme.textFaint).tracking(0.5)
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(theme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }
}
```

- [ ] **Step 2: Run xcodegen and build**

```bash
xcodegen generate
xcodebuild -target TheMargin -sdk iphonesimulator build ONLY_ACTIVE_ARCH=YES ARCHS=arm64 --quiet
```

- [ ] **Step 3: Commit**

```bash
git add Views/Insights/TrendChartView.swift
git commit -m "Add generalized TrendChartView supporting week/month/year scales"
```

---

## Task 6: Create MilestonesTimelineView

**Files:**
- Create: `Views/Insights/MilestonesTimelineView.swift`

- [ ] **Step 1: Create MilestonesTimelineView**

```swift
import SwiftUI

struct MilestonesTimelineView: View {
    let milestones: [Milestone]
    @Environment(\.marginTheme) private var theme
    @State private var showAll = false

    private var visibleMilestones: [Milestone] {
        if showAll || milestones.count <= 5 {
            return milestones
        }
        return Array(milestones.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MILESTONES")
                .font(.literata(9, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(theme.textFaint)
                .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 18) {
                ForEach(Array(visibleMilestones.enumerated()), id: \.offset) { _, milestone in
                    HStack(alignment: .top, spacing: 14) {
                        Circle()
                            .fill(theme.amber)
                            .frame(width: 10, height: 10)
                            .padding(.top, 3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(milestone.date, style: .date)
                                .font(.literata(11))
                                .foregroundStyle(theme.text.opacity(0.4))
                            HStack(spacing: 4) {
                                Text(milestone.description)
                                    .font(.display(14))
                                    .foregroundStyle(theme.text)
                                if !milestone.highlightValue.isEmpty {
                                    Text(milestone.highlightValue)
                                        .font(.display(14))
                                        .foregroundStyle(theme.amber)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.leading, 20)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(theme.amber.opacity(0.2))
                    .frame(width: 2)
                    .padding(.leading, 4)
            }

            if milestones.count > 5 && !showAll {
                Button("Show all") {
                    withAnimation { showAll = true }
                }
                .font(.literata(12))
                .foregroundStyle(theme.amber)
                .padding(.top, 12)
                .padding(.leading, 20)
            }
        }
        .padding(18)
        .background(theme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }
}
```

- [ ] **Step 2: Run xcodegen and build**

```bash
xcodegen generate
xcodebuild -target TheMargin -sdk iphonesimulator build ONLY_ACTIVE_ARCH=YES ARCHS=arm64 --quiet
```

- [ ] **Step 3: Commit**

```bash
git add Views/Insights/MilestonesTimelineView.swift
git commit -m "Add MilestonesTimelineView for Year view"
```

---

## Task 7: Refactor WritingCalendarView

Remove the period picker, week view, and year view from WritingCalendarView. It becomes a month-only calendar. The year heatmap gets inlined in InsightsView (it's simple enough). The day strip is its own component. The period picker moves to InsightsView.

**Files:**
- Modify: `Views/Insights/WritingCalendarView.swift`

- [ ] **Step 1: Simplify WritingCalendarView to month-only**

Replace the entire file content with:

```swift
import SwiftUI

struct WritingCalendarView: View {
    let wordsByDay: [Date: Int]
    @Environment(\.marginTheme) private var theme

    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        let today = Date.now
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let daysInMonth = calendar.range(of: .day, in: .month, for: today)!.count
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let maxWords = wordsByDay.values.max() ?? 1

        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day).font(.literata(9)).foregroundStyle(theme.textFaint).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(0..<(firstWeekday - 1), id: \.self) { _ in Color.clear.frame(height: 32) }
                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = calendar.date(bySetting: .day, value: day, of: monthStart)!
                    let dayStart = calendar.startOfDay(for: date)
                    let words = wordsByDay[dayStart] ?? 0
                    let intensity = maxWords > 0 ? Double(words) / Double(maxWords) : 0
                    let isToday = calendar.isDateInToday(date)
                    Text("\(day)")
                        .font(.literata(11))
                        .foregroundStyle(theme.text)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(RoundedRectangle(cornerRadius: 4).fill(theme.amber.opacity(intensity * 0.6)))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(isToday ? theme.amber : .clear, lineWidth: 1))
                }
            }
        }
    }
}
```

Note: Do NOT commit yet — InsightsView still references the old API. We update both together.

- [ ] **Step 2: Delete WeeklyTrendChartView**

```bash
rm Views/Insights/WeeklyTrendChartView.swift
```

- [ ] **Step 3: Rewrite InsightsView.swift**

Replace the entire file with the scope-tuned layout. The key change: the period picker moves here, and `mainTierContent` branches on the selected period to show different sections.

```swift
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
                        Text(selectedProjectID == nil ? "All Projects" : "Filtered")
                            .font(.literata(12)).foregroundStyle(theme.amber)
                        Image(systemName: "chevron.down").font(.system(size: 9))
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyTierContent: some View {
        VStack(spacing: 16) {
            Spacer()
            GhostChartView(style: .bars, opacity: 0.08, unlockLabel: nil, ghostColor: theme.text)
                .frame(height: 100).padding(.horizontal, 40)
            Text("\"Start before you're ready.\"")
                .font(.literata(14)).italic().foregroundStyle(theme.textDim)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Text("— Steven Pressfield")
                .font(.literata(11)).foregroundStyle(theme.textFaint)
            Text("Log your first session and your patterns will start to take shape.")
                .font(.literata(14)).foregroundStyle(theme.textDim)
                .multilineTextAlignment(.center).padding(.horizontal, 40).padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - Main Content

    private func mainTierContent(sessionCount: Int?) -> some View {
        let isLocked = sessionCount != nil

        return ScrollView {
            VStack(spacing: 20) {
                // Title
                Text("Insights")
                    .font(.display(20))
                    .foregroundStyle(theme.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                // Period picker
                Picker("Period", selection: $selectedPeriod) {
                    Text("Week").tag(InsightsPeriod.week)
                    Text("Month").tag(InsightsPeriod.month)
                    Text("Year").tag(InsightsPeriod.year)
                }
                .pickerStyle(.segmented)
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

                // Shared: Streak
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
        let wordsByDay = InsightsCalculator.wordsByDay(filteredSessions)

        // Day strip anchor
        DayStripView(wordsByDay: wordsByDay)
            .padding(.horizontal, 16)

        // Weekly trend chart
        if isLocked, let count = sessionCount {
            lockedChartSection(title: "WORDS PER WEEK", style: .line, sessionCount: count)
                .padding(.horizontal, 16)
        } else {
            let weeklyData = InsightsCalculator.wordsPerWeekTrend(filteredSessions)
            TrendChartView(
                data: weeklyData.map { (date: $0.weekStart, words: $0.words) },
                periodLabel: "THIS WEEK",
                avgLabel: "AVG / WEEK",
                centerValue: weeklyData.last?.words ?? 0,
                xAxisFormat: .dateTime.month(.abbreviated).day(),
                xAxisStride: .weekOfYear
            )
            .padding(.horizontal, 16)
        }

        // Scoped stat cards
        let periodSessions = InsightsCalculator.filteredByPeriod(filteredSessions, period: .week)
        scopedStatCards(sessions: periodSessions, period: .week)

        // Scoped mood
        MoodDistributionView(distribution: InsightsCalculator.moodDistribution(periodSessions))
            .padding(16)
            .background(theme.surface)
            .clipShape(.rect(cornerRadius: 12))
            .padding(.horizontal, 16)
    }

    // MARK: - Month Content

    @ViewBuilder
    private func monthContent(isLocked: Bool, sessionCount: Int?) -> some View {
        // Calendar heatmap anchor
        WritingCalendarView(wordsByDay: InsightsCalculator.wordsByDay(filteredSessions))
            .padding(.horizontal, 16)

        // Monthly trend chart
        if isLocked, let count = sessionCount {
            lockedChartSection(title: "WORDS PER MONTH", style: .line, sessionCount: count)
                .padding(.horizontal, 16)
        } else {
            let monthlyData = InsightsCalculator.wordsPerMonthTrend(filteredSessions)
            TrendChartView(
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
        let periodSessions = InsightsCalculator.filteredByPeriod(filteredSessions, period: .month)
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

        // Scoped stat cards
        scopedStatCards(sessions: periodSessions, period: .month)

        // Scoped mood
        MoodDistributionView(distribution: InsightsCalculator.moodDistribution(periodSessions))
            .padding(16)
            .background(theme.surface)
            .clipShape(.rect(cornerRadius: 12))
            .padding(.horizontal, 16)
    }

    // MARK: - Year Content

    @ViewBuilder
    private func yearContent(isLocked: Bool, sessionCount: Int?) -> some View {
        // Year heatmap anchor
        yearHeatmap
            .padding(.horizontal, 16)

        // Yearly trend chart
        if isLocked, let count = sessionCount {
            lockedChartSection(title: "WORDS PER MONTH", style: .line, sessionCount: count)
                .padding(.horizontal, 16)
        } else {
            let yearData = InsightsCalculator.wordsPerYearTrend(filteredSessions)
            let yearTotal = yearData.map(\.words).reduce(0, +)
            TrendChartView(
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

        // Scoped stat cards
        let periodSessions = InsightsCalculator.filteredByPeriod(filteredSessions, period: .year)
        scopedStatCards(sessions: periodSessions, period: .year)

        // Scoped mood
        MoodDistributionView(distribution: InsightsCalculator.moodDistribution(periodSessions))
            .padding(16)
            .background(theme.surface)
            .clipShape(.rect(cornerRadius: 12))
            .padding(.horizontal, 16)
    }

    // MARK: - Year Heatmap (inlined)

    private var yearHeatmap: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let wordsByDay = InsightsCalculator.wordsByDay(filteredSessions)
        let maxWords = wordsByDay.values.max() ?? 1
        let gridSpacing: CGFloat = 2
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

        return VStack(alignment: .leading, spacing: 4) {
            // Month labels
            HStack(spacing: 0) {
                ForEach(months, id: \.self) { month in
                    Text(month).font(.literata(8)).foregroundStyle(theme.textFaint).frame(maxWidth: .infinity)
                }
            }

            // Heatmap grid
            GeometryReader { geo in
                let cellSize = max(3, (geo.size.width - 51 * gridSpacing) / 52)
                let height = 7 * cellSize + 6 * gridSpacing
                LazyHGrid(rows: Array(repeating: GridItem(.fixed(cellSize), spacing: gridSpacing), count: 7), spacing: gridSpacing) {
                    ForEach(0..<364, id: \.self) { index in
                        let date = calendar.date(byAdding: .day, value: -(363 - index), to: today)!
                        let dayStart = calendar.startOfDay(for: date)
                        let words = wordsByDay[dayStart] ?? 0
                        let intensity = maxWords > 0 ? Double(words) / Double(maxWords) : 0
                        RoundedRectangle(cornerRadius: 1)
                            .fill(words > 0 ? theme.amber.opacity(0.2 + intensity * 0.6) : theme.surfaceRaised)
                            .frame(width: cellSize, height: cellSize)
                    }
                }
                .frame(height: height)
            }
            .frame(height: 56)
        }
    }

    // MARK: - Scoped Stat Cards

    @ViewBuilder
    private func scopedStatCards(sessions: [Session], period: InsightsPeriod) -> some View {
        let avgWords = InsightsCalculator.averageWordsPerSession(sessions)
        let avgDuration = InsightsCalculator.averageDurationSeconds(sessions)
        let bestDay = InsightsCalculator.bestDayOfWeek(sessions)
        let sessionCount = sessions.count
        let dayLabels = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        let periodLabel: String
        switch period {
        case .week: periodLabel = "Sessions this week"
        case .month: periodLabel = "Sessions this month"
        case .year: periodLabel = "Sessions this year"
        }

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCardView(label: "Avg words/session", value: "\(avgWords)")
            StatCardView(label: "Avg duration", value: avgDuration.map { "\($0 / 60)m" } ?? "\u{2014}")
            StatCardView(label: "Best day", value: bestDay.map { dayLabels[$0] } ?? "\u{2014}", isHighlighted: true)
            StatCardView(label: periodLabel, value: "\(sessionCount)")
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Locked Chart

    private func lockedChartSection(title: String, style: GhostChartView.Style, sessionCount: Int) -> some View {
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
```

- [ ] **Step 4: Run xcodegen and build**

```bash
xcodegen generate
xcodebuild -target TheMargin -sdk iphonesimulator build ONLY_ACTIVE_ARCH=YES ARCHS=arm64 --quiet
```

Fix any compilation errors.

- [ ] **Step 5: Run all tests**

```bash
xcodebuild test -scheme TheMargin -destination 'platform=iOS Simulator,name=iPhone 16' --quiet 2>&1 | tail -30
```

All tests should pass. If any existing tests reference `WeeklyTrendChartView`, update them.

- [ ] **Step 6: Commit**

```bash
git add Views/Insights/InsightsView.swift Views/Insights/WritingCalendarView.swift
git rm Views/Insights/WeeklyTrendChartView.swift
git commit -m "Rewrite InsightsView with scope-tuned Week/Month/Year layouts

Simplify WritingCalendarView to month-only, delete WeeklyTrendChartView
(replaced by generalized TrendChartView), add scope-specific layouts."
```

---

## Task 8: Visual QA on Simulator

Run the app on the simulator and verify each tab renders correctly.

**Files:** None (visual verification only)

- [ ] **Step 1: Build and run on simulator**

Use XcodeBuildMCP `build_run_sim` or:
```bash
xcodebuild -target TheMargin -sdk iphonesimulator build ONLY_ACTIVE_ARCH=YES ARCHS=arm64 --quiet
```

- [ ] **Step 2: Verify Week view**

Check:
- Day strip shows 7 cells with correct day initials
- Zero-word days show "0" at low opacity on surface-raised background
- Days with words show amber fill with intensity
- Today has amber border ring
- Weekly trend chart renders with 8 weeks of data
- Stat cards show week-scoped data
- Mood distribution shows week-scoped data
- Streak and goal progress appear at bottom

- [ ] **Step 3: Verify Month view**

Check:
- Calendar heatmap shows current month grid
- Monthly trend chart renders with monthly data points, labeled by month
- Day-of-week bar chart shows this month's data
- Stat cards show month-scoped data
- Mood distribution shows month-scoped data

- [ ] **Step 4: Verify Year view**

Check:
- Year heatmap renders with month labels, fits within viewport
- Yearly trend chart shows 12 months of current year
- Milestones timeline appears with at least "First session logged"
- Stat cards show year-scoped data
- Mood distribution shows year-scoped data

- [ ] **Step 5: Verify project filter**

Switch project filter and verify all scoped sections update. Verify milestones omit streak records when filtered.

- [ ] **Step 6: Verify tiering**

If possible, test with < 7 sessions to confirm locked chart sections appear correctly on each tab.

- [ ] **Step 7: Fix any visual issues found, then commit**

```bash
git add -A
git commit -m "Fix visual issues from QA pass"
```

---

## Task 9: Final Test Run and Cleanup

- [ ] **Step 1: Run full test suite**

```bash
xcodebuild test -scheme TheMargin -destination 'platform=iOS Simulator,name=iPhone 16' --quiet 2>&1 | tail -30
```

All tests must pass.

- [ ] **Step 2: Verify no stale references to WeeklyTrendChartView**

```bash
grep -r "WeeklyTrendChartView" . --include="*.swift" | grep -v ".build"
```

Expected: No results.

- [ ] **Step 3: Verify no stale references to old WritingCalendarView.Period**

```bash
grep -r "WritingCalendarView.Period" . --include="*.swift" | grep -v ".build"
```

Expected: No results.

- [ ] **Step 4: Final commit if any cleanup was needed**

```bash
git add -A
git commit -m "Clean up stale references from insights redesign"
```
