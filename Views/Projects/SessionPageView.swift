import SwiftUI

struct SessionPageView: View {
    let session: Session
    let sessionNumber: Int
    let isToday: Bool
    let onRequestDelete: () -> Void

    @Environment(\.marginTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isLifted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text(session.date, format: .dateTime.month(.abbreviated).day())
                    .font(.typewriter(11))
                    .foregroundStyle(isToday ? MarginTheme.inkBlack : MarginTheme.inkMedium)
                    .textCase(.uppercase)
                Spacer()
                MoodGlyphCompactView(mood: session.mood, size: 14, color: MarginTheme.inkBlack)
            }
            TypewriterText(text: "\(session.wordCount)", fontSize: 28)
            HStack {
                if let tag = session.chapterTag {
                    Text(tag)
                        .font(.typewriter(11))
                        .foregroundStyle(MarginTheme.inkMedium)
                }
                if let duration = session.durationSeconds {
                    Text("\(duration / 60) min")
                        .font(.mono(10))
                        .foregroundStyle(MarginTheme.inkMedium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(MarginTheme.paperDark.opacity(0.5))
                        .clipShape(.capsule)
                }
            }
            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(.grotesk(12))
                    .italic()
                    .foregroundStyle(MarginTheme.inkMedium)
                    .lineLimit(2)
            }
            HStack {
                Spacer()
                Text("#\(sessionNumber)")
                    .font(.mono(10))
                    .foregroundStyle(MarginTheme.inkMedium.opacity(0.55))
            }
        }
        .padding(16)
        .padding(.leading, 28)
        .paperSurface()
        .overlay(alignment: .topTrailing) {
            Triangle()
                .fill(MarginTheme.paperDark)
                .frame(width: 22, height: 22)
        }
        .overlay(alignment: .leading) {
            if isToday {
                Rectangle()
                    .fill(theme.accent.opacity(0.35))
                    .frame(width: theme.sessionTodayBarWidth)
            }
        }
        .offset(y: !reduceMotion && isLifted ? -6 : 0)
        .animation(reduceMotion ? nil : .spring(duration: 0.3, bounce: 0.7), value: isLifted)
        .onLongPressGesture(minimumDuration: 0.3) {
        } onPressingChanged: { pressing in
            isLifted = pressing
        }
    }
}
