import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID
    var project: Project?
    var date: Date
    var wordCount: Int
    var notes: String?
    var mood: Mood
    var durationSeconds: Int?
    var chapterTag: String?

    init(
        project: Project,
        date: Date = .now,
        wordCount: Int,
        notes: String? = nil,
        mood: Mood,
        durationSeconds: Int? = nil,
        chapterTag: String? = nil
    ) {
        self.id = UUID()
        self.project = project
        self.date = date
        self.wordCount = wordCount
        self.notes = notes
        self.mood = mood
        self.durationSeconds = durationSeconds
        self.chapterTag = chapterTag
    }
}
