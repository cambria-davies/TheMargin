import SwiftUI

struct GoalProgressCardView: View {
    let project: Project
    @Environment(\.marginTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project.name.uppercased())
                .font(.typewriter(11))
                .foregroundStyle(MarginTheme.inkLight)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(MarginTheme.inkLight.opacity(0.3), lineWidth: 0.5))
            if project.wordCountGoal > 0 {
                let progress = project.goalProgress
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(progress * 100))%").font(.display(28)).foregroundStyle(theme.amber)
                    Spacer()
                    Text("\(project.totalWords) / \(project.wordCountGoal)").font(.mono(11)).foregroundStyle(theme.textDim)
                }
                ProgressView(value: progress).tint(theme.amber)
                if let projected = InsightsCalculator.projectedCompletionDate(for: project) {
                    Text("Projected completion: \(projected, style: .date)")
                        .font(.literata(11)).foregroundStyle(theme.textDim)
                }
            } else {
                Text("No word count goal set").font(.literata(12)).foregroundStyle(theme.textFaint)
            }
        }
        .padding(16)
        .background(theme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }
}
