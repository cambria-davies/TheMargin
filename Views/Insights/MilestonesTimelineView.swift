import SwiftUI

struct MilestonesTimelineView: View {
    let milestones: [Milestone]
    @Environment(\.marginTheme) private var theme
    @State private var showAll = false

    private var visibleMilestones: [Milestone] {
        if showAll || milestones.count <= 5 {
            return milestones
        }
        return Array(milestones.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MILESTONES")
                .font(.literata(9, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(theme.textFaint)
                .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 18) {
                ForEach(visibleMilestones) { milestone in
                    HStack(alignment: .top, spacing: 14) {
                        Circle()
                            .fill(theme.amber)
                            .frame(width: 10, height: 10)
                            .padding(.top, 3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(milestone.date, style: .date)
                                .font(.literata(11))
                                .foregroundStyle(theme.text.opacity(0.4))
                            HStack(spacing: 4) {
                                Text(milestone.description)
                                    .font(.display(14))
                                    .foregroundStyle(theme.text)
                                if !milestone.highlightValue.isEmpty {
                                    Text(milestone.highlightValue)
                                        .font(.display(14))
                                        .foregroundStyle(theme.amber)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.leading, 20)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(theme.amber.opacity(0.2))
                    .frame(width: 2)
                    .padding(.leading, 4)
            }

            if milestones.count > 5 && !showAll {
                Button("Show all") {
                    withAnimation { showAll = true }
                }
                .font(.literata(12))
                .foregroundStyle(theme.amber)
                .padding(.top, 12)
                .padding(.leading, 20)
            }
        }
        .padding(18)
        .background(theme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }
}
