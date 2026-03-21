import SwiftUI

struct WritingCalendarView: View {
    let wordsByDay: [Date: Int]
    @Environment(\.marginTheme) private var theme

    private let calendar = Calendar.current
    private var daysOfWeek: [String] {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        let first = Calendar.current.firstWeekday - 1
        return Array(symbols[first...]) + Array(symbols[..<first])
    }

    var body: some View {
        let today = Date.now
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let daysInMonth = calendar.range(of: .day, in: .month, for: today)!.count
        let rawWeekday = calendar.component(.weekday, from: monthStart)
        let leadingSpaces = (rawWeekday - calendar.firstWeekday + 7) % 7
        let maxWords = wordsByDay.values.max() ?? 1

        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day).font(.literata(9)).foregroundStyle(theme.textFaint).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(0..<leadingSpaces, id: \.self) { _ in Color.clear.frame(height: 32) }
                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
                    let dayStart = calendar.startOfDay(for: date)
                    let words = wordsByDay[dayStart] ?? 0
                    let intensity = maxWords > 0 ? Double(words) / Double(maxWords) : 0
                    let isToday = calendar.isDateInToday(date)
                    Text("\(day)")
                        .font(.literata(11))
                        .foregroundStyle(theme.text)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(RoundedRectangle(cornerRadius: 4).fill(theme.amber.opacity(intensity * 0.6)))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(isToday ? theme.amber : .clear, lineWidth: 1))
                        .accessibilityLabel("\(date.formatted(.dateTime.month(.wide).day())) \(words) words")
                }
            }
        }
    }
}
