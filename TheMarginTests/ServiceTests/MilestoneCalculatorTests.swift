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
