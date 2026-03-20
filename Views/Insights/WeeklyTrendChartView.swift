import SwiftUI
import Charts

struct WeeklyTrendChartView: View {
    let weeklyData: [(weekStart: Date, words: Int)]
    @Environment(\.marginTheme) private var theme

    private var average: Int {
        guard !weeklyData.isEmpty else { return 0 }
        return weeklyData.map(\.words).reduce(0, +) / weeklyData.count
    }

    private var percentVsAverage: Int? {
        guard average > 0, let current = weeklyData.last else { return nil }
        return Int(((Double(current.words) / Double(average)) - 1.0) * 100)
    }

    var body: some View {
        VStack(spacing: 8) {
            Chart {
                ForEach(weeklyData, id: \.weekStart) { week in
                    LineMark(x: .value("Week", week.weekStart), y: .value("Words", week.words))
                        .foregroundStyle(theme.amber)
                        .interpolationMethod(.catmullRom)
                    AreaMark(x: .value("Week", week.weekStart), y: .value("Words", week.words))
                        .foregroundStyle(theme.amber.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    if week.weekStart == weeklyData.last?.weekStart {
                        PointMark(x: .value("Week", week.weekStart), y: .value("Words", week.words))
                            .foregroundStyle(theme.amber)
                            .symbolSize(40)
                            .annotation(position: .top) {
                                Text("\(week.words)").font(.mono(8)).foregroundStyle(theme.amber)
                            }
                    }
                    if week.weekStart == weeklyData.first?.weekStart {
                        PointMark(x: .value("Week", week.weekStart), y: .value("Words", week.words))
                            .foregroundStyle(theme.textFaint)
                            .symbolSize(20)
                            .annotation(position: .top) {
                                Text("\(week.words)").font(.mono(7)).foregroundStyle(theme.textFaint)
                            }
                    }
                }
                RuleMark(y: .value("Average", average))
                    .foregroundStyle(theme.textFaint)
                    .lineStyle(StrokeStyle(dash: [4, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("avg \(average)").font(.mono(8)).foregroundStyle(theme.textFaint)
                    }
            }
            .frame(height: 140)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.literata(8)).foregroundStyle(theme.textFaint)
                }
            }

            HStack {
                if let pct = percentVsAverage {
                    Text(pct >= 0 ? "+\(pct)%" : "\(pct)%")
                        .font(.display(16))
                        .foregroundStyle(pct >= 0 ? Color(hex: 0x7A9070) : Color(hex: 0x7A5C50))
                    Text("vs avg").font(.literata(8)).foregroundStyle(theme.textFaint).textCase(.uppercase)
                }
                Spacer()
                if let current = weeklyData.last {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(current.words)").font(.display(16)).foregroundStyle(theme.text)
                        Text("THIS WEEK").font(.literata(8)).foregroundStyle(theme.textFaint).tracking(0.5)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(average)").font(.display(16)).foregroundStyle(theme.text)
                    Text("AVG / WEEK").font(.literata(8)).foregroundStyle(theme.textFaint).tracking(0.5)
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(theme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }
}
