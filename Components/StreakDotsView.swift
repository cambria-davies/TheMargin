import SwiftUI

struct StreakDotsView: View {
    let sessionDates: [Date]
    @Environment(\.marginTheme) private var theme

    private let calendar = Calendar.current

    private var weekActivity: [Bool] {
        let today = calendar.startOfDay(for: .now)
        let weekStart = calendar.startOfWeek(for: today)
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            return sessionDates.contains { calendar.isDate($0, inSameDayAs: day) }
        }
    }

    private var todayIndex: Int {
        let weekday = calendar.component(.weekday, from: .now)
        // Convert to Mon=0 index (Calendar weekday: 1=Sun)
        return (weekday + 5) % 7
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                let isActive = weekActivity[index]
                let isToday = index == todayIndex

                Circle()
                    .fill(isActive ? theme.amber : .clear)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(isActive ? Color.clear : Color(hex: 0x3E3A34), lineWidth: 1.5)
                    )
                    .shadow(color: isToday ? theme.amber.opacity(0.5) : .clear, radius: isToday ? 6 : 0)
            }
        }
    }
}
