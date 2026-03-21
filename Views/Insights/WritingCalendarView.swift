import SwiftUI

struct WritingCalendarView: View {
    let wordsByDay: [Date: Int]
    @Environment(\.marginTheme) private var theme
    @State private var selectedPeriod: Period = .month

    enum Period: String, CaseIterable {
        case week = "Week", month = "Month", year = "Year"
    }

    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    private let fullDayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private static let shortMonthDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let dayOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()

    var body: some View {
        VStack(spacing: 12) {
            Picker("Period", selection: $selectedPeriod) {
                ForEach(Period.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)
            switch selectedPeriod {
            case .month: monthView
            case .week: weekView
            case .year: yearView
            }
        }
    }

    private var monthView: some View {
        let today = Date.now
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let daysInMonth = calendar.range(of: .day, in: .month, for: today)!.count
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let maxWords = wordsByDay.values.max() ?? 1

        let monthLabel = Self.monthYearFormatter.string(from: monthStart)

        return VStack(spacing: 4) {
            Text(monthLabel)
                .font(.literata(13))
                .foregroundStyle(theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 4) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day).font(.literata(9)).foregroundStyle(theme.textFaint).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(0..<(firstWeekday - 1), id: \.self) { _ in Color.clear.frame(height: 32) }
                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = calendar.date(bySetting: .day, value: day, of: monthStart)!
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
                        .accessibilityLabel("\(monthLabel) \(day), \(words) words")
                }
            }
        }
    }

    private var weekView: some View {
        let today = calendar.startOfDay(for: .now)
        let weekStart = calendar.startOfWeek(for: today)
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        let startStr = Self.shortMonthDayFormatter.string(from: weekStart)
        let isSameMonth = calendar.isDate(weekStart, equalTo: weekEnd, toGranularity: .month)
        let endStr = isSameMonth ? Self.dayOnlyFormatter.string(from: weekEnd) : Self.shortMonthDayFormatter.string(from: weekEnd)
        let weekLabel = "\(startStr)–\(endStr)"

        return VStack(spacing: 4) {
            Text(weekLabel)
                .font(.literata(13))
                .foregroundStyle(theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { offset in
                    let date = calendar.date(byAdding: .day, value: offset, to: weekStart)!
                    let dayStart = calendar.startOfDay(for: date)
                    let words = wordsByDay[dayStart] ?? 0
                    let isToday = calendar.isDate(date, inSameDayAs: today)
                    VStack(spacing: 4) {
                        Text(daysOfWeek[offset]).font(.literata(9)).foregroundStyle(theme.textFaint)
                        Text("\(words)").font(.mono(11)).foregroundStyle(words > 0 ? theme.text : theme.textFaint)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 6).fill(isToday ? theme.amberDim : theme.surface))
                    .accessibilityLabel("\(fullDayNames[offset]), \(words) words")
                }
            }
        }
    }

    private var yearView: some View {
        let year = calendar.component(.year, from: .now)
        let jan1 = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let dec31 = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!
        let totalDays = calendar.dateComponents([.day], from: jan1, to: dec31).day! + 1
        let firstWeekday = calendar.component(.weekday, from: jan1) // 1=Sun
        let totalCells = firstWeekday - 1 + totalDays
        let totalColumns = (totalCells + 6) / 7 // ceil division
        let maxWords = wordsByDay.values.max() ?? 1
        let gridSpacing: CGFloat = 2
        let monthLabels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

        // Calculate which column each month starts in
        let monthColumns: [Int] = (1...12).map { month in
            let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
            let dayOfYear = calendar.dateComponents([.day], from: jan1, to: monthStart).day!
            return (firstWeekday - 1 + dayOfYear) / 7
        }

        return GeometryReader { geo in
            let cellSize = max(3, (geo.size.width - CGFloat(totalColumns - 1) * gridSpacing) / CGFloat(totalColumns))
            let gridHeight = 7 * cellSize + 6 * gridSpacing
            let labelHeight: CGFloat = 12

            VStack(alignment: .leading, spacing: 2) {
                // Month labels positioned at their column offsets
                ZStack(alignment: .topLeading) {
                    Color.clear.frame(height: labelHeight)
                    ForEach(0..<12, id: \.self) { i in
                        Text(monthLabels[i])
                            .font(.literata(8))
                            .foregroundStyle(theme.textFaint)
                            .offset(x: CGFloat(monthColumns[i]) * (cellSize + gridSpacing))
                    }
                }

                // Heatmap grid
                LazyHGrid(rows: Array(repeating: GridItem(.fixed(cellSize), spacing: gridSpacing), count: 7), spacing: gridSpacing) {
                    ForEach(0..<(firstWeekday - 1), id: \.self) { _ in
                        Color.clear.frame(width: cellSize, height: cellSize)
                    }
                    ForEach(0..<totalDays, id: \.self) { index in
                        let date = calendar.date(byAdding: .day, value: index, to: jan1)!
                        let dayStart = calendar.startOfDay(for: date)
                        let words = wordsByDay[dayStart] ?? 0
                        let intensity = maxWords > 0 ? Double(words) / Double(maxWords) : 0
                        RoundedRectangle(cornerRadius: 1)
                            .fill(words > 0 ? theme.amber.opacity(0.2 + intensity * 0.6) : theme.surfaceRaised)
                            .frame(width: cellSize, height: cellSize)
                            .accessibilityLabel("\(Self.shortMonthDayFormatter.string(from: date)), \(words) words")
                    }
                }
                .frame(height: gridHeight)
            }
        }
        .frame(height: 66)
    }
}
