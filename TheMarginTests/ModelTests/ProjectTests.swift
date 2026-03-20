import XCTest
@testable import TheMargin

final class ProjectTests: XCTestCase {
    func testTotalWordsIncludesStartingWordCount() {
        let project = Project(name: "Novel", startingWordCount: 30000)
        let session = Session(project: project, wordCount: 500, mood: .steady)
        project.sessions = [session]
        XCTAssertEqual(project.totalWords, 30500)
    }

    func testTotalWordsWithNoSessions() {
        let project = Project(name: "Novel", startingWordCount: 10000)
        XCTAssertEqual(project.totalWords, 10000)
    }

    func testGoalProgressCalculation() throws {
        let project = Project(name: "Novel", wordCountGoal: 80000, startingWordCount: 40000)
        let progress = try XCTUnwrap(project.goalProgress)
        XCTAssertEqual(progress, 0.5, accuracy: 0.001)
    }

    func testGoalProgressNilWhenNoGoal() {
        let project = Project(name: "Blog")
        XCTAssertNil(project.goalProgress)
    }

    func testGoalProgressCapsAtOne() {
        let project = Project(name: "Short", wordCountGoal: 1000, startingWordCount: 2000)
        XCTAssertEqual(project.goalProgress, 1.0)
    }

    func testVisualPageCount() {
        let project = Project(name: "Novel", startingWordCount: 10000)
        XCTAssertEqual(project.visualPageCount, 40)
    }

    func testVisualPageCountMinimumOne() {
        let project = Project(name: "Started")
        let session = Session(project: project, wordCount: 100, mood: .grinding)
        project.sessions = [session]
        XCTAssertEqual(project.visualPageCount, 1)
    }

    func testVisualPageCountZeroWhenEmpty() {
        let project = Project(name: "Empty")
        XCTAssertEqual(project.visualPageCount, 0)
    }
}
