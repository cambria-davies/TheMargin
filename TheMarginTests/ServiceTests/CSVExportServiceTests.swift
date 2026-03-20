import XCTest
@testable import TheMargin

final class CSVExportServiceTests: XCTestCase {
    func testCSVHeaderRow() {
        let csv = CSVExportService.generate(sessions: [])
        XCTAssertTrue(csv.hasPrefix("Date,Project,Word Count,Mood,Chapter,Duration (min),Notes"))
    }

    func testCSVRowFormat() {
        let project = Project(name: "Novel")
        let session = Session(
            project: project,
            date: ISO8601DateFormatter().date(from: "2026-03-15T10:00:00Z")!,
            wordCount: 1200,
            notes: "Good session",
            mood: .flow,
            durationSeconds: 3600,
            chapterTag: "Ch. 5"
        )
        let csv = CSVExportService.generate(sessions: [session])
        let lines = csv.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 3) // header + 1 row + trailing newline
        XCTAssertTrue(lines[1].contains("Novel"))
        XCTAssertTrue(lines[1].contains("1200"))
        XCTAssertTrue(lines[1].contains("Flow"))
        XCTAssertTrue(lines[1].contains("Ch. 5"))
        XCTAssertTrue(lines[1].contains("60"))
    }

    func testCSVEscapesCommasInNotes() {
        let project = Project(name: "Novel")
        let session = Session(
            project: project,
            wordCount: 500,
            notes: "Wrote about love, loss, and hope",
            mood: .steady
        )
        let csv = CSVExportService.generate(sessions: [session])
        XCTAssertTrue(csv.contains("\"Wrote about love, loss, and hope\""))
    }
}
