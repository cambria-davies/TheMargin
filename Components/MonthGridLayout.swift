import Foundation

/// Shared grid computation for a calendar month.
/// Both `WritingCalendarView` and `MonthStreakSidebarView` consume this.
struct MonthGridLayout {
    let monthStart: Date
    let leadingSpaces: Int
    let daysInMonth: Int
    let rowCount: Int

    init(monthStart: Date, calendar: Calendar = .current) {
        self.monthStart = monthStart
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let rawWeekday = calendar.component(.weekday, from: monthStart)
        let leadingSpaces = (rawWeekday - calendar.firstWeekday + 7) % 7
        let rowCount = (leadingSpaces + daysInMonth + 6) / 7
        self.daysInMonth = daysInMonth
        self.leadingSpaces = leadingSpaces
        self.rowCount = rowCount
    }
}
