import SwiftUI

struct StreakDotsView: View {
    let sessionDates: [Date]
    @Environment(\.marginTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

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
        let sessionDaySet = Set(sessionDates.map { calendar.startOfDay(for: $0) })
        return (0..<7).map { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return false }
            return sessionDaySet.contains(calendar.startOfDay(for: day))
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
                        .font(.grotesk(9, weight: .semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(isToday ? theme.accent : theme.textSecondary)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .frame(width: columnWidth)

                    Circle()
                        .fill(isActive ? theme.accent : .clear)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(
                                    isActive ? Color.clear : theme.borderLight,
                                    lineWidth: colorScheme == .dark ? 1.5 : 1.25
                                )
                        )
                        .shadow(
                            color: isToday ? theme.accent.opacity(colorScheme == .dark ? 0.85 : 0.45) : .clear,
                            radius: isToday ? (colorScheme == .dark ? 12 : 6) : 0
                        )
                }
                .frame(width: columnWidth)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
