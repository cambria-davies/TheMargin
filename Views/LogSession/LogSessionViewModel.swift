import SwiftUI
import SwiftData

enum LogSessionValidationError: LocalizedError {
    case invalidInput

    var errorDescription: String? {
        "Enter a positive word count and select a mood before saving."
    }
}

@MainActor @Observable
class LogSessionViewModel {
    var wordCountText: String = ""
    var selectedMood: Mood?
    var notes: String = ""
    var chapterTag: String = ""
    var prefilledDurationSeconds: Int?

    var parsedWordCount: Int? {
        let cleaned = wordCountText.replacing(",", with: "")
        return Int(cleaned)
    }

    var canSave: Bool {
        guard let wc = parsedWordCount, wc > 0, selectedMood != nil else { return false }
        return true
    }

    func save(project: Project, editing session: Session? = nil, context: ModelContext) throws {
        guard let wordCount = parsedWordCount, let mood = selectedMood, wordCount > 0 else {
            throw LogSessionValidationError.invalidInput
        }

        let target = session ?? Session(
            project: project,
            wordCount: wordCount,
            notes: notes.isEmpty ? nil : notes,
            mood: mood,
            durationSeconds: prefilledDurationSeconds,
            chapterTag: chapterTag.isEmpty ? nil : chapterTag
        )

        target.project = project
        target.wordCount = wordCount
        target.notes = notes.isEmpty ? nil : notes
        target.mood = mood
        target.durationSeconds = prefilledDurationSeconds
        target.chapterTag = chapterTag.isEmpty ? nil : chapterTag

        if session == nil {
            context.insert(target)
        }

        try context.save()
    }
}
