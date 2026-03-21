import SwiftUI

struct DayStripView: View {
    let wordsByDay: [Date: Int]
    @Environment(\.marginTheme) private var theme

    private let calendar = Calendar.current
    private var dayInitials: [String] {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        let first = Calendar.current.firstWeekday - 1
        return Array(symbols[first...]) + Array(symbols[..<first])
    }

    var body: some View {
        let today = calendar.startOfDay(for: .now)
        let weekStart = calendar.startOfWeek(for: today)
        let days = (0..<7).map { offset -> (date: Date, words: Int) in
            let date = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            let dayStart = calendar.startOfDay(for: date)
            return (date: dayStart, words: wordsByDay[dayStart] ?? 0)
        }
        let maxWords = days.map(\.words).max() ?? 1

        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { index in
                let day = days[index]
                let isToday = calendar.isDate(day.date, inSameDayAs: today)
                let intensity = day.words > 0 && maxWords > 0
                    ? max(0.2, min(1.0, Double(day.words) / Double(maxWords)))
                    : 0

                VStack(spacing: 4) {
                    Text(dayInitials[index])
                        .font(.literata(11))
                        .foregroundStyle(isToday ? theme.amber : theme.textFaint)
                    Text(day.words > 9999 ? formatCompact(day.words) : "\(day.words)")
                        .font(.mono(14))
                        .foregroundStyle(day.words > 0 ? (intensity > 0.8 ? theme.background : theme.amber) : theme.textFaint)
                        .opacity(day.words > 0 ? 1.0 : 0.35)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(day.words > 0 ? theme.amber.opacity(intensity) : theme.surfaceRaised)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isToday ? theme.amber : .clear, lineWidth: 2)
                )
            }
        }
    }

    private func formatCompact(_ value: Int) -> String {
        if value >= 10000 {
            let k = Double(value) / 1000.0
            return String(format: "%.1fk", k)
        }
        return "\(value)"
    }
}
