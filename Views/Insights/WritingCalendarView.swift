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

    private var monthStart: Date? {
        calendar.date(from: calendar.dateComponents([.year, .month], from: Date.now))
    }

    var body: some View {
        if let monthStart {
        let layout = MonthGridLayout(monthStart: monthStart, calendar: calendar)
        let maxWords = wordsByDay.values.max() ?? 1

        VStack(spacing: 8) {
            Text(monthStart.formatted(.dateTime.month(.wide).year()))
                .font(.display(16))
                .foregroundStyle(theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Day-of-week headers
            LazyVGrid(columns: gridColumns, spacing: 6) {
                ForEach(daysOfWeek.indices, id: \.self) { i in
                    Text(daysOfWeek[i])
                        .font(.mono(12))
                        .foregroundStyle(theme.textTertiary)
                }
            }
            .padding(.trailing, sidebarReserve)

            // Calendar grid with sidebar
            ZStack(alignment: .topTrailing) {
                LazyVGrid(columns: gridColumns, spacing: 6) {
                    ForEach(0..<layout.leadingSpaces, id: \.self) { _ in Color.clear.frame(height: 44) }
                    ForEach(1...layout.daysInMonth, id: \.self) { day in
                        if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                            let dayStart = calendar.startOfDay(for: date)
                            let words = wordsByDay[dayStart] ?? 0
                            let intensity = maxWords > 0 ? Double(words) / Double(maxWords) : 0
                            let isToday = calendar.isDateInToday(date)
                            Text("\(day)")
                                .font(.mono(14))
                                .foregroundStyle(theme.text)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Rectangle().fill(theme.accent.opacity(intensity * 0.6)))
                                .overlay(Rectangle().strokeBorder(isToday ? theme.accent : .clear, lineWidth: isToday ? 1 : 0))
                                .accessibilityLabel("\(date.formatted(.dateTime.month(.wide).day())) \(words) words")
                        }
                    }
                }
                .padding(.trailing, sidebarReserve)

                MonthStreakSidebarView(wordsByDay: wordsByDay, monthStart: monthStart)
            }
        }
        }
    }
}
