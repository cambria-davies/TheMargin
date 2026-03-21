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

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let sidebarReserve = MonthStreakSidebarView.sidebarWidth + 8

    var body: some View {
        let today = Date.now
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let layout = MonthGridLayout(monthStart: monthStart, calendar: calendar)
        let maxWords = wordsByDay.values.max() ?? 1

        VStack(spacing: 8) {
            Text(monthStart.formatted(.dateTime.month(.wide).year()))
                .font(.literata(16))
                .foregroundStyle(theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Day-of-week headers
            LazyVGrid(columns: gridColumns, spacing: 6) {
                ForEach(daysOfWeek.indices, id: \.self) { i in
                    Text(daysOfWeek[i])
                        .font(.literata(12))
                        .foregroundStyle(theme.textFaint)
                }
            }
            .padding(.trailing, sidebarReserve)

            // Calendar grid with sidebar
            ZStack(alignment: .topTrailing) {
                LazyVGrid(columns: gridColumns, spacing: 6) {
                    ForEach(0..<layout.leadingSpaces, id: \.self) { _ in Color.clear.frame(height: 44) }
                    ForEach(1...layout.daysInMonth, id: \.self) { day in
                        let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
                        let dayStart = calendar.startOfDay(for: date)
                        let words = wordsByDay[dayStart] ?? 0
                        let intensity = maxWords > 0 ? Double(words) / Double(maxWords) : 0
                        let isToday = calendar.isDateInToday(date)
                        Text("\(day)")
                            .font(.literata(14))
                            .foregroundStyle(theme.text)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(RoundedRectangle(cornerRadius: 6).fill(theme.amber.opacity(intensity * 0.6)))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(isToday ? theme.amber : .clear, lineWidth: 1.5))
                            .accessibilityLabel("\(date.formatted(.dateTime.month(.wide).day())) \(words) words")
                    }
                }
                .padding(.trailing, sidebarReserve)

                MonthStreakSidebarView(wordsByDay: wordsByDay, monthStart: monthStart)
            }
        }
    }
}
