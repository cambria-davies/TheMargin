import SwiftUI

struct ProjectCardView: View {
    let project: Project
    let isCurrent: Bool
    @Environment(\.marginTheme) private var theme

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
                            .font(.literata(9, weight: .medium))
                            .foregroundStyle(theme.amber)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.amberDim)
                            .clipShape(.capsule)
                    }
                }
                Text("\(project.totalWords) words")
                    .font(.mono(11))
                    .foregroundStyle(theme.textDim)
                if project.wordCountGoal > 0 {
                    ProgressView(value: project.goalProgress)
                        .tint(theme.amber)
                    Text("Goal: \(project.wordCountGoal)")
                        .font(.literata(10))
                        .foregroundStyle(theme.textFaint)
                }
                if let lastSession = project.sessions.sorted(by: { $0.date > $1.date }).first {
                    Text("Last session: \(lastSession.date, style: .date)")
                        .font(.literata(10))
                        .italic()
                        .foregroundStyle(theme.textFaint)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(theme.textFaint)
        }
        .padding(16)
        .background(theme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }
}
