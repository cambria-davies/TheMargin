import SwiftUI

struct GoalProgressCardView: View {
    let project: Project
    @Environment(\.marginTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project.name.uppercased())
                .font(.typewriter(11))
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
            if project.wordCountGoal > 0 {
                let progress = project.goalProgress
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(progress * 100))%")
                        .font(.displayTabular(28, weight: .semibold))
                        .foregroundStyle(theme.accent)
                        .monospacedDigit()
                    Spacer()
                    Text("\(project.totalWords) / \(project.wordCountGoal)").font(.mono(11)).foregroundStyle(theme.textSecondary)
                }
                ProgressView(value: progress).tint(theme.accent)
                if let projected = InsightsCalculator.projectedCompletionDate(for: project) {
                    Text("Projected completion: \(projected, style: .date)")
                        .font(.mono(11)).foregroundStyle(theme.textSecondary)
                }
            } else {
                Text("No word count goal set").font(.grotesk(12)).foregroundStyle(theme.textTertiary)
            }
        }
        .padding(16)
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
}
