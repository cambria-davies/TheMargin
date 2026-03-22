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

    private static let wordCountFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f
    }()

    var body: some View {
        let today = calendar.startOfDay(for: .now)
        let weekStart = calendar.startOfWeek(for: today)
        let days = (0..<7).map { offset -> (date: Date, words: Int) in
            let date = calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
            let dayStart = calendar.startOfDay(for: date)
            return (date: dayStart, words: wordsByDay[dayStart] ?? 0)
        }

        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let isSameMonth = calendar.isDate(weekStart, equalTo: weekEnd, toGranularity: .month)
        let startStr = weekStart.formatted(.dateTime.month(.abbreviated).day())
        let endStr = isSameMonth ? weekEnd.formatted(.dateTime.day()) : weekEnd.formatted(.dateTime.month(.abbreviated).day())

        VStack(alignment: .leading, spacing: 10) {
            Text("\(startStr) – \(endStr)")
                .font(.mono(12))
                .foregroundStyle(theme.textTertiary)

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { index in
                    let day = days[index]
                    let isToday = calendar.isDate(day.date, inSameDayAs: today)
                    dayCell(
                        date: day.date,
                        dayInitial: dayInitials[index],
                        words: day.words,
                        isToday: isToday
                    )
                }
            }

            Rectangle()
                .fill(theme.borderLight)
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func dayCell(date: Date, dayInitial: String, words: Int, isToday: Bool) -> some View {
        let hasWords = words > 0
        let letterColor = isToday ? theme.text : theme.textTertiary
        let letterWeight: Font.Weight = isToday ? .semibold : .regular

        let valueString: String = {
            if words > 9999 { return formatCompact(words) }
            return Self.wordCountFormatter.string(from: NSNumber(value: words)) ?? "\(words)"
        }()

        let valueColor: Color = {
            if isToday { return theme.text }
            if hasWords { return theme.text }
            return theme.textTertiary
        }()

        VStack(spacing: 4) {
            Text(dayInitial)
                .font(.grotesk(11, weight: letterWeight))
                .textCase(.uppercase)
                .foregroundStyle(letterColor)

            Text(valueString)
                .font(isToday ? .displayTabular(13, weight: .semibold) : .displayTabular(11, weight: hasWords ? .medium : .regular))
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 2)
        .background(
            Rectangle()
                .fill(cellBackground(isToday: isToday))
        )
        .overlay {
            Rectangle().strokeBorder(theme.border, lineWidth: 1)
        }
        .accessibilityLabel("\(date.formatted(.dateTime.weekday(.wide))), \(words) words")
    }

    private func cellBackground(isToday: Bool) -> Color {
        isToday ? theme.surfaceDark : theme.surface
    }

    private func formatCompact(_ value: Int) -> String {
        if value >= 10000 {
            let k = Double(value) / 1000.0
            return String(format: "%.1fk", k)
        }
        return Self.wordCountFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
