import Foundation

struct StreakResult: Sendable {
    let current: Int
    let longest: Int
    let atRisk: Bool
}

enum StreakCalculator {
    static func calculate(sessionDates: [Date]) -> StreakResult {
        guard !sessionDates.isEmpty else {
            return StreakResult(current: 0, longest: 0, atRisk: false)
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let uniqueDays = Set(sessionDates.map { calendar.startOfDay(for: $0) })
            .sorted(by: >)

        var streaks: [Int] = []
        var currentRun = 1

        for i in 1..<uniqueDays.count {
            guard let expected = calendar.date(byAdding: .day, value: -1, to: uniqueDays[i - 1]) else { continue }
            if calendar.isDate(uniqueDays[i], inSameDayAs: expected) {
                currentRun += 1
            } else {
                streaks.append(currentRun)
                currentRun = 1
            }
        }
        streaks.append(currentRun)

        let longest = streaks.max() ?? 0

        let mostRecent = uniqueDays[0]
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            return StreakResult(current: 0, longest: longest, atRisk: false)
        }

        let includesCurrent = calendar.isDate(mostRecent, inSameDayAs: today)
            || calendar.isDate(mostRecent, inSameDayAs: yesterday)

        let currentStreak = includesCurrent ? streaks[0] : 0
        let atRisk = !calendar.isDate(mostRecent, inSameDayAs: today)
            && calendar.isDate(mostRecent, inSameDayAs: yesterday)

        return StreakResult(
            current: currentStreak,
            longest: longest,
            atRisk: atRisk
        )
    }
}
