import SwiftUI

struct MoodSelectorView: View {
    @Binding var selected: Mood?

    var body: some View {
        HStack(spacing: 16) {
            ForEach(Mood.allCases, id: \.self) { mood in
                Button {
                    withAnimation(.easeOut(duration: 0.4)) {
                        selected = mood
                    }
                } label: {
                    MoodGlyphView(
                        mood: mood,
                        isSelected: selected == mood,
                        size: 36
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mood.displayName)
                .sensoryFeedback(
                    selected == mood ? .impact(weight: .medium) : .impact(weight: .light),
                    trigger: selected
                )
            }
        }
    }
}
