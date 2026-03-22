import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var wordCountGoal: Int
    var startingWordCount: Int
    var createdAt: Date
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \Session.project)
    var sessions: [Session]

    var totalWords: Int {
        startingWordCount + sessions.reduce(0) { $0 + $1.wordCount }
    }

    var wordsToday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)
        return sessions
            .filter { calendar.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.wordCount }
    }

    var goalProgress: Double {
        guard wordCountGoal > 0 else { return 0.0 }
        return min(Double(totalWords) / Double(wordCountGoal), 1.0)
    }

    /// Dashboard-equivalent visual page count (max 40): matches `ManuscriptStackView` — goal-relative when `wordCountGoal > 0`.
    var visualPageCount: Int {
        guard totalWords > 0 else { return 0 }
        let maxDashboardPages = 40
        if wordCountGoal > 0 {
            let progress = min(1.0, Double(totalWords) / Double(wordCountGoal))
            let pages = Int(ceil(progress * Double(maxDashboardPages)))
            return min(maxDashboardPages, max(1, pages))
        }
        let pagesFromWords = (totalWords + 249) / 250
        return min(maxDashboardPages, max(1, pagesFromWords))
    }

    init(
        name: String,
        wordCountGoal: Int,
        startingWordCount: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.wordCountGoal = wordCountGoal
        self.startingWordCount = startingWordCount
        self.createdAt = Date.now
        self.isArchived = false
        self.sessions = []
    }
}
