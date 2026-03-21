import SwiftUI

struct MonthStreakSidebarView: View {
    let wordsByDay: [Date: Int]
    let monthStart: Date

    @Environment(\.marginTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appearedRows: Set<Int> = []
    @State private var lastCheckmarkAppeared = false

    // Row height matches WritingCalendarView's LazyVGrid: 32pt cell + 4pt spacing
    private let rowHeight: CGFloat = 32
    private let rowSpacing: CGFloat = 4

    private var layout: MonthGridLayout {
        MonthGridLayout(monthStart: monthStart)
    }

    private var checked: [Bool] {
        Self.checkedRows(wordsByDay: wordsByDay, monthStart: monthStart)
    }

    private var activeCount: Int {
        checked.filter { $0 }.count
    }

    var body: some View {
        let rows = layout.rowCount
        let totalHeight = CGFloat(rows) * rowHeight + CGFloat(rows - 1) * rowSpacing

        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                // Amber gradient track
                let firstCenter = rowHeight / 2
                let lastCenter = totalHeight - rowHeight / 2
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [theme.amber.opacity(0.6), theme.amber.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 6, height: lastCenter - firstCenter)
                    .offset(y: firstCenter)

                // Marks for each row
                ForEach(0..<rows, id: \.self) { row in
                    let isFilled = checked[row]
                    let yCenter = CGFloat(row) * (rowHeight + rowSpacing) + rowHeight / 2

                    markView(row: row, isFilled: isFilled)
                        .position(x: 18, y: yCenter)
                }
            }
            .frame(width: 36, height: totalHeight)

            // Flame at bottom
            Text("🔥")
                .font(.system(size: 22))
                .padding(.top, 4)
                .accessibilityLabel("Current streak indicator.")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Monthly writing activity, \(activeCount) of \(layout.rowCount) weeks active.")
        .frame(width: 36)
        .sensoryFeedback(.impact(weight: .light), trigger: lastCheckmarkAppeared)
        .onAppear {
            animateMarks()
        }
    }

    @ViewBuilder
    private func markView(row: Int, isFilled: Bool) -> some View {
        let appeared = appearedRows.contains(row)

        if isFilled {
            ZStack {
                Circle()
                    .fill(theme.amber)
                    .frame(width: 20, height: 20)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(appeared ? 1 : 0)
            .accessibilityLabel("Week \(row + 1), wrote this week.")
        } else {
            Circle()
                .fill(theme.surfaceRaised)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color(hex: 0x444444), lineWidth: 1)
                )
                .opacity(appeared ? 0.6 : 0)
                .accessibilityLabel("Week \(row + 1), no writing.")
        }
    }

    private func animateMarks() {
        let rows = layout.rowCount
        let checkedValues = checked

        if reduceMotion {
            // All marks appear instantly
            for row in 0..<rows {
                appearedRows.insert(row)
            }
            if checkedValues.contains(true) {
                lastCheckmarkAppeared.toggle()
            }
            return
        }

        // Staggered animation
        for row in 0..<rows {
            let delay = Double(row) * 0.08
            let isFilled = checkedValues[row]

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if isFilled {
                    _ = withAnimation(.spring(duration: 0.35, bounce: 0.3)) {
                        appearedRows.insert(row)
                    }
                    // If this is the last filled checkmark, trigger haptic
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
    }

    // MARK: - Testable Logic

    /// Computes which calendar rows (weeks) have at least one day with writing activity.
    /// Returns an array of booleans, one per row, where `true` means the row has ≥1 day with words > 0.
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
            // Verify the date is actually in this month
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

    // Sample data: wrote on days 2, 5, 10, 15, 22
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
