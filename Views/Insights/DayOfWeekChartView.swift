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
                .font(.literata(9, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(theme.textFaint)

            Chart {
                ForEach(1...7, id: \.self) { weekday in
                    BarMark(
                        x: .value("Day", dayLabels[weekday - 1]),
                        y: .value("Words", wordsByDayOfWeek[weekday] ?? 0)
                    )
                    .foregroundStyle(weekday == bestDay ? theme.amber : theme.surfaceRaised)
                    .clipShape(.rect(cornerRadius: 4))
                }
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().font(.literata(10)).foregroundStyle(theme.textDim)
                }
            }
            .frame(height: 120)
        }
    }
}
