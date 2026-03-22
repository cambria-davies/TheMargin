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
        let goal = project.wordCountGoal
        guard goal > 0 else { return nil }
        let remaining = goal - project.totalWords
        guard remaining > 0 else { return nil }

        let sessions = project.sessions.sorted(by: { $0.date < $1.date })
        guard sessions.count >= 2 else { return nil }

        let calendar = Calendar.current
        guard let firstDate = sessions.first?.date, let lastDate = sessions.last?.date else { return nil }
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

    static func wordsPerMonthTrend(_ sessions: [Session], months: Int? = nil) -> [(monthStart: Date, words: Int)] {
        let calendar = Calendar.current
        let today = Date.now

        // Auto-detect range from first session, capped at 24
        let monthCount: Int
        if let months = months {
            monthCount = min(months, 24)
        } else if let earliest = sessions.min(by: { $0.date < $1.date })?.date {
            let comps = calendar.dateComponents([.month], from: earliest, to: today)
            monthCount = min((comps.month ?? 0) + 1, 24)
        } else {
            monthCount = 1
        }

        var result: [(monthStart: Date, words: Int)] = []

        for monthsAgo in (0..<monthCount).reversed() {
            let monthDate = calendar.date(byAdding: .month, value: -monthsAgo, to: today)!
            let comps = calendar.dateComponents([.year, .month], from: monthDate)
            let monthStart = calendar.date(from: comps)!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            let monthWords = sessions
                .filter { $0.date >= monthStart && $0.date < nextMonth }
                .reduce(0) { $0 + $1.wordCount }
            result.append((monthStart: monthStart, words: monthWords))
        }
        return result
    }

    static func wordsPerYearTrend(_ sessions: [Session]) -> [(monthStart: Date, words: Int)] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date.now)
        var result: [(monthStart: Date, words: Int)] = []

        for month in 1...12 {
            let comps = DateComponents(year: year, month: month)
            let monthStart = calendar.date(from: comps)!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            let monthWords = sessions
                .filter { $0.date >= monthStart && $0.date < nextMonth }
                .reduce(0) { $0 + $1.wordCount }
            result.append((monthStart: monthStart, words: monthWords))
        }
        return result
    }

    static func sessionCount(_ sessions: [Session], period: InsightsPeriod) -> Int {
        filteredByPeriod(sessions, period: period).count
    }

    static func periodTotal(_ sessions: [Session], period: InsightsPeriod) -> Int {
        filteredByPeriod(sessions, period: period).reduce(0) { $0 + $1.wordCount }
    }

    static func filteredByPeriod(_ sessions: [Session], period: InsightsPeriod) -> [Session] {
        let calendar = Calendar.current
        let now = Date.now
        let start: Date
        switch period {
        case .week:
            start = calendar.startOfWeek(for: now)
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: now)
            start = calendar.date(from: comps)!
        case .year:
            let comps = calendar.dateComponents([.year], from: now)
            start = calendar.date(from: comps)!
        }
        return sessions.filter { $0.date >= start }
    }
}

// MARK: - Insights Period

enum InsightsPeriod: Hashable {
    case week, month, year

    var label: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .year: "Year"
        }
    }
}

// MARK: - Calendar helper
extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}
