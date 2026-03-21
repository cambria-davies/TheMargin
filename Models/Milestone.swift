import Foundation

enum MilestoneKind: Equatable, Hashable {
    case firstSession
    case streakRecord(days: Int)
    case goalReached(projectName: String, goal: Int)
    case mostProductiveDay(words: Int)
    case biggestSession(words: Int)
}

struct Milestone: Equatable, Identifiable {
    let date: Date
    let kind: MilestoneKind

    var id: String {
        "\(date.timeIntervalSince1970)-\(kind)"
    }

    var description: String {
        switch kind {
        case .firstSession:
            return "First session logged"
        case .streakRecord:
            return "Longest streak"
        case .goalReached(let name, _):
            return "\(name) goal reached"
        case .mostProductiveDay:
            return "Most productive day"
        case .biggestSession:
            return "Biggest session"
        }
    }

    var highlightValue: String {
        switch kind {
        case .firstSession:
            return ""
        case .streakRecord(let days):
            return "\(days) days"
        case .goalReached(_, let goal):
            return "\(goal.formatted()) words"
        case .mostProductiveDay(let words):
            return "\(words.formatted()) words"
        case .biggestSession(let words):
            return "\(words.formatted()) words"
        }
    }
}
