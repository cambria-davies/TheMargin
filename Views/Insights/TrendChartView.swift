import SwiftUI
import Charts

struct TrendChartView: View {
    let title: String            // Section title, e.g. "WORDS PER WEEK"
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

    /// Short caption for the footer (e.g. "AVG / WK").
    private var footerAvgCaption: String {
        let u = avgLabel.uppercased()
        if u.contains("WEEK") { return "AVG / WK" }
        if u.contains("MONTH") { return "AVG / MO" }
        return avgLabel.uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.mono(9, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(theme.textTertiary)

                Chart {
                    ForEach(Array(data.enumerated()), id: \.element.date) { index, entry in
                        LineMark(x: .value("Period", entry.date), y: .value("Words", entry.words))
                            .foregroundStyle(theme.accent)
                            .interpolationMethod(.linear)
                        AreaMark(x: .value("Period", entry.date), y: .value("Words", entry.words))
                            .foregroundStyle(theme.accent.opacity(0.08))
                            .interpolationMethod(.linear)
                        if index == data.count - 1 {
                            PointMark(x: .value("Period", entry.date), y: .value("Words", entry.words))
                                .foregroundStyle(theme.accent)
                                .symbolSize(40)
                                .annotation(position: .top) {
                                    Text("\(entry.words)").font(.mono(8)).foregroundStyle(theme.accent)
                                }
                        }
                        if index == 0 {
                            PointMark(x: .value("Period", entry.date), y: .value("Words", entry.words))
                                .foregroundStyle(theme.textTertiary)
                                .symbolSize(20)
                                .annotation(position: .top) {
                                    Text("\(entry.words)").font(.mono(7)).foregroundStyle(theme.textTertiary)
                                }
                        }
                    }
                    RuleMark(y: .value("Average", average))
                        .foregroundStyle(theme.textTertiary)
                        .lineStyle(StrokeStyle(dash: [4, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("avg \(Self.formattedInteger(average))")
                                .font(.mono(8))
                                .foregroundStyle(theme.textTertiary)
                        }
                }
                .frame(height: 140)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: .stride(by: xAxisStride)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: xAxisFormat)
                            .font(.mono(8)).foregroundStyle(theme.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            trendChartFooter
        }
        .background(theme.surface)
        .overlay {
            CardPaperNoise()
                .clipShape(Rectangle())
                .allowsHitTesting(false)
        }
        .clipShape(Rectangle())
        .overlay {
            Rectangle().strokeBorder(theme.border, lineWidth: 1)
        }
    }

    private var trendChartFooter: some View {
        let pct = percentVsAverage
        let vsText: String = {
            guard let p = pct else { return "—" }
            return p >= 0 ? "+\(p)%" : "\(p)%"
        }()

        return VStack(spacing: 0) {
            Rectangle()
                .fill(theme.borderLight)
                .frame(height: 1)

            GeometryReader { geo in
                HStack(spacing: 0) {
                    footerColumn(value: vsText, caption: "VS AVG")
                    Rectangle()
                        .fill(theme.borderLight)
                        .frame(width: 1, height: geo.size.height)
                    footerColumn(value: Self.formattedInteger(centerValue), caption: periodLabel.uppercased())
                    Rectangle()
                        .fill(theme.borderLight)
                        .frame(width: 1, height: geo.size.height)
                    footerColumn(value: Self.formattedInteger(average), caption: footerAvgCaption)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            }
            .frame(height: 72)
        }
        .background(theme.surface)
    }

    private func footerColumn(value: String, caption: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.display(18, weight: .semibold))
                .foregroundStyle(theme.text)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(caption)
                .font(.mono(8, weight: .semibold))
                .foregroundStyle(theme.textSecondary)
                .tracking(0.8)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
    }

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    private static func formattedInteger(_ n: Int) -> String {
        decimalFormatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
