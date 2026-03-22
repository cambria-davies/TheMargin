import SwiftUI

private struct MilestoneLastRowHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct MilestonesTimelineView: View {
    let milestones: [Milestone]
    @Environment(\.marginTheme) private var theme
    @State private var showAll = false
    @State private var lastRowHeight: CGFloat = 0

    private let timelineColumnWidth: CGFloat = 20
    private let circleSize: CGFloat = 10
    private let circleTopPadding: CGFloat = 3

    private var timelineDotColumnHeight: CGFloat {
        circleTopPadding + circleSize
    }

    private var milestoneDotCenterYOffset: CGFloat {
        circleTopPadding + circleSize / 2
    }

    private var visibleMilestones: [Milestone] {
        if showAll || milestones.count <= 5 {
            return milestones
        }
        return Array(milestones.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MILESTONES")
                .font(.mono(9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(theme.textTertiary)
                .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 18) {
                ForEach(Array(visibleMilestones.enumerated()), id: \.element.id) { index, milestone in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(theme.accent)
                            .frame(width: circleSize, height: circleSize)
                            .padding(.top, circleTopPadding)
                            .frame(width: timelineColumnWidth, height: timelineDotColumnHeight, alignment: .top)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(milestone.date, style: .date)
                                .font(.mono(11))
                                .foregroundStyle(theme.text.opacity(0.4))
                            HStack(spacing: 4) {
                                Text(milestone.description)
                                    .font(.display(14))
                                    .foregroundStyle(theme.text)
                                if !milestone.highlightValue.isEmpty {
                                    Text(milestone.highlightValue)
                                        .font(.display(14))
                                        .foregroundStyle(theme.accent)
                                }
                            }
                        }
                    }
                    .background(alignment: .topLeading) {
                        if index == visibleMilestones.count - 1 {
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: MilestoneLastRowHeightKey.self,
                                    value: proxy.size.height
                                )
                            }
                        }
                    }
                }
            }
            .onPreferenceChange(MilestoneLastRowHeightKey.self) { lastRowHeight = $0 }
            .overlay(alignment: .topLeading) {
                GeometryReader { proxy in
                    let totalHeight = proxy.size.height
                    let lineHeight: CGFloat = {
                        guard lastRowHeight > 0 else { return 0 }
                        return max(0, totalHeight - lastRowHeight)
                    }()
                    Rectangle()
                        .fill(theme.accent.opacity(0.2))
                        .frame(width: 2)
                        .frame(height: lineHeight)
                        .padding(.leading, (timelineColumnWidth - 2) / 2)
                        .offset(y: milestoneDotCenterYOffset)
                }
                .frame(width: timelineColumnWidth, alignment: .leading)
            }

            if milestones.count > 5 && !showAll {
                Button("Show all") {
                    withAnimation { showAll = true }
                }
                .font(.grotesk(12))
                .foregroundStyle(theme.accent)
                .padding(.top, 12)
                .padding(.leading, timelineColumnWidth + 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(theme.surface)
        .clipShape(Rectangle())
        .overlay {
            Rectangle().strokeBorder(theme.border, lineWidth: 1)
        }
    }
}
