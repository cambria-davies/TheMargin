import Foundation

enum InsightsCalculator {
    static func averageWordsPerSession(_ sessions: [Session]) -> Int {
        guard !sessions.isEmpty else { return 0 }
        return sessions.reduce(0) { $0 + $1.wordCount } / sessions.count
    }

    static func averageDurationSeconds(_ sessions: [Session]) -> Int? {
        let timed = sessions.compactMap(\.durationSeconds)
        guard !timed.isEmpty else { return nil }
        return timed.reduce(0, +) / timed.count
    }

    static func bestDayOfWeek(_ sessions: [Session]) -> Int? {
        guard !sessions.isEmpty else { return nil }
        let calendar = Calendar.current
        var totals: [Int: Int] = [:]
        for session in sessions {
            let weekday = calendar.component(.weekday, from: session.date)
            totals[weekday, default: 0] += session.wordCount
        }
        return totals.max(by: { $0.value < $1.value })?.key
    }

    static func wordsByDayOfWeek(_ sessions: [Session]) -> [Int: Int] {
        let calendar = Calendar.current
        var totals: [Int: Int] = [:]
        for session in sessions {
            let weekday = calendar.component(.weekday, from: session.date)
            totals[weekday, default: 0] += session.wordCount
        }
        return totals
    }

    static func wordsPerWeekTrend(_ sessions: [Session], weeks: Int = 8) -> [(weekStart: Date, words: Int)] {
        let calendar = Calendar.current
        let today = Date.now
        var result: [(weekStart: Date, words: Int)] = []

        for weeksAgo in (0..<weeks).reversed() {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: today)!
            let start = calendar.startOfWeek(for: weekStart)
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            let weekWords = sessions
                .filter { $0.date >= start && $0.date < end }
                .reduce(0) { $0 + $1.wordCount }
            result.append((weekStart: start, words: weekWords))
        }
        return result
    }

    static func moodDistribution(_ sessions: [Session]) -> [Mood: Double] {
        guard !sessions.isEmpty else { return [:] }
        var counts: [Mood: Int] = [:]
        for session in sessions {
            counts[session.mood, default: 0] += 1
        }
        return counts.mapValues { Double($0) / Double(sessions.count) }
    }

    static func projectedCompletionDate(for project: Project) -> Date? {
        guard let goal = project.wordCountGoal, goal > 0 else { return nil }
        let remaining = goal - project.totalWords
        guard remaining > 0 else { return nil }

        let sessions = project.sessions.sorted(by: { $0.date < $1.date })
        guard sessions.count >= 2 else { return nil }

        let calendar = Calendar.current
        let firstDate = sessions.first!.date
        let lastDate = sessions.last!.date
        let daySpan = max((calendar.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0) + 1, 1)
        let totalWritten = sessions.reduce(0) { $0 + $1.wordCount }
        let wordsPerDay = Double(totalWritten) / Double(daySpan)

        guard wordsPerDay > 0 else { return nil }
        let daysRemaining = Int(ceil(Double(remaining) / wordsPerDay))
        return calendar.date(byAdding: .day, value: daysRemaining, to: Date.now)
    }

    static func wordsByDay(_ sessions: [Session]) -> [Date: Int] {
        let calendar = Calendar.current
        var result: [Date: Int] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.date)
            result[day, default: 0] += session.wordCount
        }
        return result
    }

    static func thisWeekTotal(_ sessions: [Session]) -> Int {
        let calendar = Calendar.current
        let weekStart = calendar.startOfWeek(for: .now)
        return sessions
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + $1.wordCount }
    }
}

// MARK: - Calendar helper
extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}
