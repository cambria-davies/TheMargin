import SwiftUI

struct StreakDotsView: View {
    let sessionDates: [Date]
    @Environment(\.marginTheme) private var theme

    private let calendar = Calendar.current
    /// Fixed column width keeps labels centered over dots and matches `spacing` math.
    private let columnWidth: CGFloat = 18

    /// Weekday initials in calendar order (matches `startOfWeek` + day offsets).
    private var dayInitials: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...]) + Array(symbols[..<first])
    }

    private var weekActivity: [Bool] {
        let today = calendar.startOfDay(for: .now)
        let weekStart = calendar.startOfDay(for: calendar.startOfWeek(for: today))
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            return sessionDates.contains { calendar.isDate($0, inSameDayAs: day) }
        }
    }

    private var todayIndex: Int {
        let today = calendar.startOfDay(for: .now)
        let weekStart = calendar.startOfDay(for: calendar.startOfWeek(for: today))
        return calendar.dateComponents([.day], from: weekStart, to: today).day ?? 0
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                let isActive = weekActivity[index]
                let isToday = index == todayIndex

                VStack(spacing: 4) {
                    Text(dayInitials[index])
                        .font(.literata(9))
                        .foregroundStyle(isToday ? theme.amber : theme.textDim)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .frame(width: columnWidth)

                    Circle()
                        .fill(isActive ? theme.amber : .clear)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(isActive ? Color.clear : Color(hex: 0x3E3A34), lineWidth: 1.5)
                        )
                        .shadow(color: isToday ? theme.amber.opacity(0.5) : .clear, radius: isToday ? 6 : 0)
                }
                .frame(width: columnWidth)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
