import XCTest
@testable import TheMargin

final class InsightsCalculatorTests: XCTestCase {
    private let calendar = Calendar.current

    private func makeSession(
        daysAgo: Int,
        wordCount: Int,
        mood: Mood = .steady,
        durationSeconds: Int? = nil
    ) -> Session {
        let project = Project(name: "Test", wordCountGoal: 0)
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date.now)!
        return Session(
            project: project,
            date: date,
            wordCount: wordCount,
            mood: mood,
            durationSeconds: durationSeconds
        )
    }

    func testAverageWordsPerSession() {
        let sessions = [
            makeSession(daysAgo: 0, wordCount: 500),
            makeSession(daysAgo: 1, wordCount: 1000),
            makeSession(daysAgo: 2, wordCount: 750),
        ]
        let result = InsightsCalculator.averageWordsPerSession(sessions)
        XCTAssertEqual(result, 750)
    }

    func testAverageDurationExcludesUntimedSessions() {
        let sessions = [
            makeSession(daysAgo: 0, wordCount: 500, durationSeconds: 3600),
            makeSession(daysAgo: 1, wordCount: 500, durationSeconds: 1800),
            makeSession(daysAgo: 2, wordCount: 500, durationSeconds: nil),
        ]
        let result = InsightsCalculator.averageDurationSeconds(sessions)
        XCTAssertEqual(result, 2700)
    }

    func testMoodDistribution() {
        let sessions = [
            makeSession(daysAgo: 0, wordCount: 500, mood: .flow),
            makeSession(daysAgo: 1, wordCount: 500, mood: .flow),
            makeSession(daysAgo: 2, wordCount: 500, mood: .steady),
            makeSession(daysAgo: 3, wordCount: 500, mood: .dry),
        ]
        let dist = InsightsCalculator.moodDistribution(sessions)
        XCTAssertEqual(dist[.flow]!, 0.5, accuracy: 0.01)
        XCTAssertEqual(dist[.steady]!, 0.25, accuracy: 0.01)
        XCTAssertEqual(dist[.dry]!, 0.25, accuracy: 0.01)
    }

    func testProjectedCompletionDate() {
        let sessions = (0..<10).map { makeSession(daysAgo: $0, wordCount: 500) }
        let project = Project(name: "Novel", wordCountGoal: 30000, startingWordCount: 0)
        project.sessions = sessions
        let projected = InsightsCalculator.projectedCompletionDate(for: project)
        XCTAssertNotNil(projected)
        let daysUntil = calendar.dateComponents([.day], from: Date.now, to: projected!).day!
        XCTAssertEqual(daysUntil, 50, accuracy: 10)
    }

    func testEmptySessionsReturnZeros() {
        XCTAssertEqual(InsightsCalculator.averageWordsPerSession([]), 0)
        XCTAssertNil(InsightsCalculator.averageDurationSeconds([]))
        XCTAssertTrue(InsightsCalculator.moodDistribution([]).isEmpty)
    }

    private func makeProject() -> Project {
        Project(name: "Test", wordCountGoal: 0)
    }

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
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekStart = calendar.startOfWeek(for: today)
        // Place sessions precisely: one today (in week), one before week start (out of week)
        let inWeek = Session(project: makeProject(), date: today, wordCount: 500, mood: .steady)
        let outOfWeek = Session(project: makeProject(), date: calendar.date(byAdding: .day, value: -1, to: weekStart)!, wordCount: 300, mood: .steady)
        let weekCount = InsightsCalculator.sessionCount([inWeek, outOfWeek], period: .week)
        XCTAssertEqual(weekCount, 1)
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
}
