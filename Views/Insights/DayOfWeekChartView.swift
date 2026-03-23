import SwiftUI
import Charts

struct DayOfWeekChartView: View {
    let wordsByDayOfWeek: [Int: Int]
    let bestDay: Int?
    @Environment(\.marginTheme) private var theme
    private let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WORDS BY DAY")
                .font(.mono(9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(theme.textTertiary)

            Chart {
                ForEach(1...7, id: \.self) { weekday in
                    BarMark(
                        x: .value("Day", dayLabels[weekday - 1]),
                        y: .value("Words", wordsByDayOfWeek[weekday] ?? 0)
                    )
                    .foregroundStyle(weekday == bestDay ? theme.accent : theme.chartBarMuted)
                    .clipShape(Rectangle())
                }
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.mono(10, weight: .medium))
                        .foregroundStyle(theme.chartAxisLabel)
                }
            }
            .frame(height: 120)
        }
    }
}
