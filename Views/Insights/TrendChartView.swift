import SwiftUI
import Charts

struct TrendChartView: View {
    let data: [(date: Date, words: Int)]
    let periodLabel: String      // "THIS WEEK", "THIS MONTH", "THIS YEAR"
    let avgLabel: String         // "AVG / WEEK", "AVG / MONTH"
    let centerValue: Int         // Explicit center stat — last data point for week/month, sum for year
    let xAxisFormat: Date.FormatStyle // Controls how x-axis labels render
    let xAxisStride: Calendar.Component // .weekOfYear, .month

    @Environment(\.marginTheme) private var theme

    private var average: Int {
        guard !data.isEmpty else { return 0 }
        return data.map(\.words).reduce(0, +) / data.count
    }

    private var percentVsAverage: Int? {
        guard average > 0 else { return nil }
        return Int(((Double(centerValue) / Double(average)) - 1.0) * 100)
    }

    var body: some View {
        VStack(spacing: 8) {
            Chart {
                ForEach(Array(data.enumerated()), id: \.element.date) { index, entry in
                    LineMark(x: .value("Period", entry.date), y: .value("Words", entry.words))
                        .foregroundStyle(theme.amber)
                        .interpolationMethod(.catmullRom)
                    AreaMark(x: .value("Period", entry.date), y: .value("Words", entry.words))
                        .foregroundStyle(theme.amber.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    if index == data.count - 1 {
                        PointMark(x: .value("Period", entry.date), y: .value("Words", entry.words))
                            .foregroundStyle(theme.amber)
                            .symbolSize(40)
                            .annotation(position: .top) {
                                Text("\(entry.words)").font(.mono(8)).foregroundStyle(theme.amber)
                            }
                    }
                    if index == 0 {
                        PointMark(x: .value("Period", entry.date), y: .value("Words", entry.words))
                            .foregroundStyle(theme.textFaint)
                            .symbolSize(20)
                            .annotation(position: .top) {
                                Text("\(entry.words)").font(.mono(7)).foregroundStyle(theme.textFaint)
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
                AxisMarks(values: .stride(by: xAxisStride)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: xAxisFormat)
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
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(centerValue)").font(.display(16)).foregroundStyle(theme.text)
                    Text(periodLabel).font(.literata(8)).foregroundStyle(theme.textFaint).tracking(0.5)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(average)").font(.display(16)).foregroundStyle(theme.text)
                    Text(avgLabel).font(.literata(8)).foregroundStyle(theme.textFaint).tracking(0.5)
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(theme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }
}
