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
}
