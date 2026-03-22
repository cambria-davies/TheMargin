import SwiftUI

struct MonthStreakSidebarView: View {
    let wordsByDay: [Date: Int]
    let monthStart: Date

    @Environment(\.marginTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appearedRows: Set<Int> = []
    @State private var lastCheckmarkAppeared = false

    static let sidebarWidth: CGFloat = 40

    private let rowHeight: CGFloat = 44
    private let rowSpacing: CGFloat = 6
    private let bubbleSize: CGFloat = 16

    private var layout: MonthGridLayout {
        MonthGridLayout(monthStart: monthStart)
    }

    /// Number of complete weeks (rows with ≥ 4 days) to display bubbles for.
    private var displayRowCount: Int {
        let totalSlots = layout.leadingSpaces + layout.daysInMonth
        let lastRowDays = totalSlots % 7
        // Drop the last row if it has fewer than 4 days (partial week)
        if lastRowDays > 0 && lastRowDays < 4 {
            return layout.rowCount - 1
        }
        return layout.rowCount
    }

    private var checked: [Bool] {
        let all = Self.checkedRows(wordsByDay: wordsByDay, monthStart: monthStart)
        return Array(all.prefix(displayRowCount))
    }

    /// Longest run of consecutive `true` values in `checked` — the actual weekly streak.
    private var streakCount: Int {
        var longest = 0
        var current = 0
        for active in checked {
            if active {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
        }
        return longest
    }

    var body: some View {
        let rows = displayRowCount
        let totalHeight = CGFloat(rows) * rowHeight + CGFloat(rows - 1) * rowSpacing

        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                // Track — same gradient style as StreakBarView
                let firstCenter = rowHeight / 2
                let lastCenter = totalHeight - rowHeight / 2
                Rectangle()
                    .fill(theme.borderLight)
                    .frame(width: 4, height: lastCenter - firstCenter)
                    .offset(y: firstCenter)

                // Filled portion of track
                let filledRows = checked.lastIndex(of: true).map { $0 + 1 } ?? 0
                if filledRows > 0 {
                    let filledEnd = CGFloat(filledRows - 1) * (rowHeight + rowSpacing) + rowHeight / 2
                    Rectangle()
                        .fill(theme.accent)
                        .frame(width: 4, height: filledEnd - firstCenter)
                        .offset(y: firstCenter)
                }

                // Bubbles for each row
                ForEach(0..<rows, id: \.self) { row in
                    let isFilled = checked[row]
                    let yCenter = CGFloat(row) * (rowHeight + rowSpacing) + rowHeight / 2

                    bubbleView(row: row, isFilled: isFilled)
                        .position(x: 20, y: yCenter)
                }
            }
            .frame(width: 40, height: totalHeight)

            // Completed active weeks count at bottom
            VStack(spacing: 0) {
                Text("\(streakCount)")
                    .font(.mono(16))
                    .foregroundStyle(streakCount > 0 ? theme.accent : theme.textTertiary)
                Text(streakCount == 1 ? "week" : "weeks")
                    .font(.grotesk(9))
                    .foregroundStyle(theme.textTertiary)
                Text("STREAK")
                    .font(.mono(9, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(theme.textTertiary)
            }
            .padding(.top, 6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Monthly writing streak, \(streakCount) consecutive \(streakCount == 1 ? "week" : "weeks") of \(displayRowCount).")
        .frame(width: Self.sidebarWidth)
        .sensoryFeedback(.impact(weight: .light), trigger: lastCheckmarkAppeared)
        .task {
            await animateMarks()
        }
    }

    @ViewBuilder
    private func bubbleView(row: Int, isFilled: Bool) -> some View {
        let appeared = appearedRows.contains(row)

        Circle()
            .fill(isFilled ? theme.accent : theme.surfaceDark.opacity(0.8))
            .overlay(
                Circle()
                    .stroke(isFilled ? theme.accent.opacity(0.5) : theme.textTertiary.opacity(0.3), lineWidth: 1)
            )
            .frame(width: bubbleSize, height: bubbleSize)
            .scaleEffect(appeared ? 1 : (isFilled ? 0 : 0.8))
            .opacity(appeared ? 1 : 0)
            .accessibilityLabel(isFilled ? "Week \(row + 1), wrote this week." : "Week \(row + 1), no writing.")
    }

    private func animateMarks() async {
        let rows = displayRowCount
        let checkedValues = checked

        if reduceMotion {
            for row in 0..<rows {
                appearedRows.insert(row)
            }
            if checkedValues.contains(true) {
                lastCheckmarkAppeared.toggle()
            }
            return
        }

        for row in 0..<rows {
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled else { return }
            let isFilled = checkedValues[row]
            if isFilled {
                _ = withAnimation(.spring(duration: 0.35, bounce: 0.3)) {
                    appearedRows.insert(row)
                }
                let isLastFilled = checkedValues[(row + 1)...].allSatisfy { !$0 }
                if isLastFilled {
                    lastCheckmarkAppeared.toggle()
                }
            } else {
                _ = withAnimation(.easeIn(duration: 0.2)) {
                    appearedRows.insert(row)
                }
            }
        }
    }

    // MARK: - Testable Logic

    static func checkedRows(
        wordsByDay: [Date: Int],
        monthStart: Date,
        calendar: Calendar = .current
    ) -> [Bool] {
        let layout = MonthGridLayout(monthStart: monthStart, calendar: calendar)
        var result = [Bool](repeating: false, count: layout.rowCount)

        for (date, words) in wordsByDay {
            guard words > 0 else { continue }
            let day = calendar.component(.day, from: date)
            guard calendar.isDate(date, equalTo: monthStart, toGranularity: .month) else { continue }
            let slotIndex = layout.leadingSpaces + day - 1
            let row = slotIndex / 7
            if row >= 0 && row < layout.rowCount {
                result[row] = true
            }
        }

        return result
    }
}

#Preview {
    let calendar = Calendar.current
    let monthStart = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!

    let sampleDays = [2, 5, 10, 15, 22]
    let wordsByDay: [Date: Int] = Dictionary(
        uniqueKeysWithValues: sampleDays.map { day in
            (calendar.date(from: DateComponents(year: 2026, month: 3, day: day))!, 500)
        }
    )

    MonthStreakSidebarView(wordsByDay: wordsByDay, monthStart: monthStart)
        .padding()
        .background(Color.black)
}
