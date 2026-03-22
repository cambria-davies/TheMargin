import XCTest
@testable import TheMargin

final class ProjectTests: XCTestCase {
    func testTotalWordsIncludesStartingWordCount() {
        let project = Project(name: "Novel", wordCountGoal: 0, startingWordCount: 30000)
        let session = Session(project: project, wordCount: 500, mood: .steady)
        project.sessions = [session]
        XCTAssertEqual(project.totalWords, 30500)
    }

    func testTotalWordsWithNoSessions() {
        let project = Project(name: "Novel", wordCountGoal: 0, startingWordCount: 10000)
        XCTAssertEqual(project.totalWords, 10000)
    }

    func testGoalProgressCalculation() {
        let project = Project(name: "Novel", wordCountGoal: 80000, startingWordCount: 40000)
        XCTAssertEqual(project.goalProgress, 0.5, accuracy: 0.001)
    }

    func testGoalProgressZeroWhenGoalIsZero() {
        let project = Project(name: "Blog", wordCountGoal: 0)
        XCTAssertEqual(project.goalProgress, 0.0)
    }

    func testGoalProgressCapsAtOne() {
        let project = Project(name: "Short", wordCountGoal: 1000, startingWordCount: 2000)
        XCTAssertEqual(project.goalProgress, 1.0)
    }

    func testVisualPageCount() {
        let project = Project(name: "Novel", wordCountGoal: 0, startingWordCount: 10000)
        XCTAssertEqual(project.visualPageCount, 40)
    }

    func testVisualPageCountScalesToGoal() {
        let half = Project(name: "Half", wordCountGoal: 100_000, startingWordCount: 50_000)
        XCTAssertEqual(half.visualPageCount, 20)
        let full = Project(name: "Full", wordCountGoal: 80_000, startingWordCount: 80_000)
        XCTAssertEqual(full.visualPageCount, 40)
        let over = Project(name: "Over", wordCountGoal: 50_000, startingWordCount: 100_000)
        XCTAssertEqual(over.visualPageCount, 40)
    }

    func testVisualPageCountMinimumOne() {
        let project = Project(name: "Started", wordCountGoal: 0)
        let session = Session(project: project, wordCount: 100, mood: .grinding)
        project.sessions = [session]
        XCTAssertEqual(project.visualPageCount, 1)
    }

    func testVisualPageCountZeroWhenEmpty() {
        let project = Project(name: "Empty", wordCountGoal: 0)
        XCTAssertEqual(project.visualPageCount, 0)
    }
}
