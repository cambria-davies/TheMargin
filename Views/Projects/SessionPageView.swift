import SwiftUI

struct SessionPageView: View {
    let session: Session
    let sessionNumber: Int
    let isToday: Bool
    let onRequestDelete: () -> Void

    @State private var isLifted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.date, format: .dateTime.month(.abbreviated).day())
                    .font(.typewriter(11))
                    .foregroundStyle(MarginTheme.inkLight)
                    .textCase(.uppercase)
                Spacer()
                Text(session.mood.glyph)
                    .foregroundStyle(session.mood.color)
            }
            TypewriterText(text: "\(session.wordCount)", fontSize: 28)
            HStack {
                if let tag = session.chapterTag {
                    Text(tag)
                        .font(.typewriter(11))
                        .foregroundStyle(MarginTheme.inkLight)
                }
                if let duration = session.durationSeconds {
                    Text("\(duration / 60) min")
                        .font(.mono(10))
                        .foregroundStyle(MarginTheme.inkLight)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(MarginTheme.paperDark.opacity(0.5))
                        .clipShape(.capsule)
                }
            }
            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(.literata(12))
                    .italic()
                    .foregroundStyle(MarginTheme.inkMedium)
                    .lineLimit(2)
            }
            HStack {
                Spacer()
                Text("#\(sessionNumber)")
                    .font(.literata(10))
                    .foregroundStyle(MarginTheme.inkLight.opacity(0.5))
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
                    .fill(Color(hex: 0xC4956A).opacity(0.3))
                    .frame(width: 3)
            }
        }
        .offset(y: isLifted ? -6 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLifted)
        .onLongPressGesture(minimumDuration: 0.3) {
        } onPressingChanged: { pressing in
            isLifted = pressing
        }
    }
}
