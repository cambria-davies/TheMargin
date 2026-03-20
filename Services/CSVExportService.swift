import Foundation

enum CSVExportService {
    static func generate(sessions: [Session]) -> String {
        var csv = "Date,Project,Word Count,Mood,Chapter,Duration (min),Notes\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let sorted = sessions.sorted(by: { $0.date > $1.date })

        for session in sorted {
            let date = dateFormatter.string(from: session.date)
            let project = escapeCSV(session.project?.name ?? "Unknown")
            let words = "\(session.wordCount)"
            let mood = session.mood.displayName
            let chapter = escapeCSV(session.chapterTag ?? "")
            let duration = session.durationSeconds.map { "\($0 / 60)" } ?? ""
            let notes = escapeCSV(session.notes ?? "")

            csv += "\(date),\(project),\(words),\(mood),\(chapter),\(duration),\(notes)\n"
        }
        return csv
    }

    private static func escapeCSV(_ value: String) -> String {
        let guardedValue: String
        if let first = value.first, ["=", "+", "-", "@"].contains(String(first)) {
            guardedValue = "'\(value)"
        } else {
            guardedValue = value
        }

        if guardedValue.contains(",") || guardedValue.contains("\"") || guardedValue.contains("\n") {
            return "\"\(guardedValue.replacing("\"", with: "\"\""))\""
        }
        return guardedValue
    }
}
