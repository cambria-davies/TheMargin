import Foundation

enum MilestoneCalculator {
    static func calculate(sessions: [Session], projects: [Project], includeStreaks: Bool = true) -> [Milestone] {
        guard !sessions.isEmpty else { return [] }

        let sorted = sessions.sorted { $0.date < $1.date }
        var milestones: [Milestone] = []
        let calendar = Calendar.current

        // First session
        milestones.append(Milestone(date: sorted[0].date, kind: .firstSession))

        // Streak records — collect complete streak runs, emit a milestone for each that sets a new all-time record
        let uniqueDays = Set(sorted.map { calendar.startOfDay(for: $0.date) }).sorted()
        if includeStreaks {
            // Build list of (streakLength, lastDayOfStreak)
            var streakRuns: [(length: Int, lastDay: Date)] = []
            var currentStreak = 1
            for i in 1..<uniqueDays.count {
                let expected = calendar.date(byAdding: .day, value: 1, to: uniqueDays[i - 1])!
                if calendar.isDate(uniqueDays[i], inSameDayAs: expected) {
                    currentStreak += 1
                } else {
                    streakRuns.append((length: currentStreak, lastDay: uniqueDays[i - 1]))
                    currentStreak = 1
                }
            }
            // Append the final run
            if !uniqueDays.isEmpty {
                streakRuns.append((length: currentStreak, lastDay: uniqueDays[uniqueDays.count - 1]))
            }
            // Emit a milestone only when a run sets a new record (length > 1 required)
            var maxStreak = 1
            for run in streakRuns {
                if run.length > maxStreak {
                    maxStreak = run.length
                    milestones.append(Milestone(date: run.lastDay, kind: .streakRecord(days: maxStreak)))
                }
            }
        }

        // Goal reached — scan sessions chronologically per project
        for project in projects where project.wordCountGoal > 0 {
            let projectSessions = sorted.filter { $0.project?.id == project.id }
            var cumulative = project.startingWordCount
            for session in projectSessions {
                let wasBelowGoal = cumulative < project.wordCountGoal
                cumulative += session.wordCount
                if wasBelowGoal && cumulative >= project.wordCountGoal {
                    milestones.append(Milestone(
                        date: session.date,
                        kind: .goalReached(projectName: project.name, goal: project.wordCountGoal)
                    ))
                    break
                }
            }
        }

        // Biggest session — earliest date wins ties
        if let biggest = sorted.max(by: {
            ($0.wordCount, $1.date) < ($1.wordCount, $0.date)
        }) {
            milestones.append(Milestone(date: biggest.date, kind: .biggestSession(words: biggest.wordCount)))
        }

        // Most productive day — sum words per day, earliest date wins ties
        var wordsByDay: [Date: Int] = [:]
        for session in sorted {
            let day = calendar.startOfDay(for: session.date)
            wordsByDay[day, default: 0] += session.wordCount
        }
        if let (day, words) = wordsByDay.max(by: {
            ($0.value, $1.key) < ($1.value, $0.key)
        }) {
            milestones.append(Milestone(date: day, kind: .mostProductiveDay(words: words)))
        }

        // Sort newest first
        milestones.sort { $0.date > $1.date }
        return milestones
    }
}
