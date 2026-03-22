import SwiftUI

struct ProjectCardView: View {
    let project: Project
    let isCurrent: Bool
    @Environment(\.marginTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            ManuscriptStackView(totalWords: project.totalWords, goalWords: project.wordCountGoal > 0 ? project.wordCountGoal : nil, size: .thumbnail)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(project.name)
                        .font(.display(16))
                        .foregroundStyle(theme.text)
                    if isCurrent {
                        Text("Current")
                            .font(.mono(9, weight: .semibold))
                            .foregroundStyle(colorScheme == .dark ? theme.background : theme.surface)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.accent)
                            .clipShape(.capsule)
                    }
                }
                Text("\(project.totalWords) words")
                    .font(.mono(11))
                    .foregroundStyle(theme.textSecondary)
                if project.wordCountGoal > 0 {
                    ProgressView(value: project.goalProgress)
                        .tint(theme.accent)
                    Text("Goal: \(project.wordCountGoal)")
                        .font(.grotesk(10))
                        .foregroundStyle(theme.textTertiary)
                }
                if let lastSession = project.sessions.max(by: { $0.date < $1.date }) {
                    Text("Last session: \(lastSession.date, style: .date)")
                        .font(.mono(10))
                        .italic()
                        .foregroundStyle(theme.textTertiary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(theme.textTertiary)
        }
        .padding(16)
        .background(theme.surface)
        .overlay(alignment: .leading) {
            HStack(spacing: 0) {
                if isCurrent {
                    Rectangle()
                        .fill(theme.accent)
                        .frame(width: 4)
                }
                Rectangle()
                    .fill(MarginTheme.redMargin)
                    .frame(width: 1)
                    .padding(.leading, 12)
            }
        }
        .clipShape(.rect(cornerRadius: 12))
        .overlay {
            CardPaperNoise()
                .clipShape(.rect(cornerRadius: 12))
        }
    }
}
