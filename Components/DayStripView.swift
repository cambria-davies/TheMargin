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

        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        let isSameMonth = calendar.isDate(weekStart, equalTo: weekEnd, toGranularity: .month)
        let startStr = weekStart.formatted(.dateTime.month(.abbreviated).day())
        let endStr = isSameMonth ? weekEnd.formatted(.dateTime.day()) : weekEnd.formatted(.dateTime.month(.abbreviated).day())

        VStack(alignment: .leading, spacing: 6) {
            Text("\(startStr)–\(endStr)")
                .font(.literata(13))
                .foregroundStyle(theme.text)

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
                            .foregroundStyle(intensity > 0.5 ? theme.background : (isToday ? theme.amber : theme.textDim))
                        Text(day.words > 9999 ? formatCompact(day.words) : "\(day.words)")
                            .font(.mono(14))
                            .foregroundStyle(day.words > 0 ? (intensity > 0.8 ? theme.background : theme.amber) : theme.textDim)
                            .opacity(day.words > 0 ? 1.0 : 0.5)
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
                    .accessibilityLabel("\(day.date.formatted(.dateTime.weekday(.wide))), \(day.words) words")
                }
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
