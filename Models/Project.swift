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

    var visualPageCount: Int {
        max(totalWords / 250, totalWords > 0 ? 1 : 0)
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
