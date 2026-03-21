import XCTest
@testable import TheMargin

final class SessionTests: XCTestCase {
    func testSessionCreationWithRequiredFields() {
        let project = Project(name: "Novel", wordCountGoal: 80000)
        let session = Session(project: project, wordCount: 1000, mood: .steady)

        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.wordCount, 1000)
        XCTAssertEqual(session.mood, .steady)
    }

    func testSessionDefaultOptionalFieldsAreNil() {
        let project = Project(name: "Novel", wordCountGoal: 80000)
        let session = Session(project: project, wordCount: 500, mood: .flow)

        XCTAssertNil(session.notes)
        XCTAssertNil(session.durationSeconds)
        XCTAssertNil(session.chapterTag)
    }

    func testSessionWithNotes() {
        let project = Project(name: "Novel", wordCountGoal: 80000)
        let session = Session(project: project, wordCount: 300, mood: .grinding, notes: "Struggled with the opening scene")

        XCTAssertEqual(session.notes, "Struggled with the opening scene")
    }

    func testSessionWithDuration() {
        let project = Project(name: "Novel", wordCountGoal: 80000)
        let session = Session(project: project, wordCount: 750, mood: .flow, durationSeconds: 1800)

        XCTAssertEqual(session.durationSeconds, 1800)
    }

    func testSessionWithChapterTag() {
        let project = Project(name: "Novel", wordCountGoal: 80000)
        let session = Session(project: project, wordCount: 400, mood: .steady, chapterTag: "Chapter 3")

        XCTAssertEqual(session.chapterTag, "Chapter 3")
    }

    func testSessionWithAllOptionalFields() {
        let project = Project(name: "Novel", wordCountGoal: 80000)
        let session = Session(
            project: project,
            wordCount: 2000,
            notes: "Best writing session this month",
            mood: .breakthrough,
            durationSeconds: 3600,
            chapterTag: "Climax"
        )

        XCTAssertEqual(session.wordCount, 2000)
        XCTAssertEqual(session.notes, "Best writing session this month")
        XCTAssertEqual(session.mood, .breakthrough)
        XCTAssertEqual(session.durationSeconds, 3600)
        XCTAssertEqual(session.chapterTag, "Climax")
    }

    func testSessionProjectRelationship() {
        let project = Project(name: "Memoir", wordCountGoal: 50000)
        let session = Session(project: project, wordCount: 600, mood: .dry)

        XCTAssertEqual(session.project?.name, "Memoir")
    }

    func testSessionMoodAllCases() {
        let project = Project(name: "Novel", wordCountGoal: 80000)

        let dry = Session(project: project, wordCount: 100, mood: .dry)
        let grinding = Session(project: project, wordCount: 200, mood: .grinding)
        let steady = Session(project: project, wordCount: 300, mood: .steady)
        let flow = Session(project: project, wordCount: 400, mood: .flow)
        let breakthrough = Session(project: project, wordCount: 500, mood: .breakthrough)

        XCTAssertEqual(dry.mood, .dry)
        XCTAssertEqual(grinding.mood, .grinding)
        XCTAssertEqual(steady.mood, .steady)
        XCTAssertEqual(flow.mood, .flow)
        XCTAssertEqual(breakthrough.mood, .breakthrough)
    }

    func testSessionDefaultDateIsSet() {
        let before = Date()
        let project = Project(name: "Novel", wordCountGoal: 80000)
        let session = Session(project: project, wordCount: 500, mood: .steady)
        let after = Date()

        XCTAssertGreaterThanOrEqual(session.date, before)
        XCTAssertLessThanOrEqual(session.date, after)
    }

    func testSessionCustomDateIsPreserved() {
        let customDate = Date(timeIntervalSince1970: 1_700_000_000)
        let project = Project(name: "Novel", wordCountGoal: 80000)
        let session = Session(project: project, date: customDate, wordCount: 500, mood: .steady)

        XCTAssertEqual(session.date, customDate)
    }

    func testSessionZeroWordCount() {
        let project = Project(name: "Novel", wordCountGoal: 80000)
        let session = Session(project: project, wordCount: 0, mood: .dry)

        XCTAssertEqual(session.wordCount, 0)
    }

    func testEachSessionHasUniqueID() {
        let project = Project(name: "Novel", wordCountGoal: 80000)
        let session1 = Session(project: project, wordCount: 100, mood: .steady)
        let session2 = Session(project: project, wordCount: 200, mood: .flow)

        XCTAssertNotEqual(session1.id, session2.id)
    }
}
