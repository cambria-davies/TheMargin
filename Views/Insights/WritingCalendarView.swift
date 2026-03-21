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

        return VStack(spacing: 4) {
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
                }
            }
        }
    }

    private var weekView: some View {
        let today = calendar.startOfDay(for: .now)
        let weekStart = calendar.startOfWeek(for: today)
        return HStack(spacing: 8) {
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
            }
        }
    }

    private var yearView: some View {
        let today = calendar.startOfDay(for: .now)
        let maxWords = wordsByDay.values.max() ?? 1
        let gridSpacing: CGFloat = 2
        // 52 weeks × 7 days = 364 cells
        return GeometryReader { geo in
            let cellSize = max(3, (geo.size.width - 51 * gridSpacing) / 52)
            let height = 7 * cellSize + 6 * gridSpacing
            LazyHGrid(rows: Array(repeating: GridItem(.fixed(cellSize), spacing: gridSpacing), count: 7), spacing: gridSpacing) {
                ForEach(0..<364, id: \.self) { index in
                    let date = calendar.date(byAdding: .day, value: -(363 - index), to: today)!
                    let dayStart = calendar.startOfDay(for: date)
                    let words = wordsByDay[dayStart] ?? 0
                    let intensity = maxWords > 0 ? Double(words) / Double(maxWords) : 0
                    RoundedRectangle(cornerRadius: 1)
                        .fill(words > 0 ? theme.amber.opacity(0.2 + intensity * 0.6) : theme.surfaceRaised)
                        .frame(width: cellSize, height: cellSize)
                }
            }
            .frame(height: height)
        }
        .frame(height: 50)
    }
}
