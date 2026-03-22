import SwiftUI

struct PenFABView: View {
    @State private var isExpanded = false
    let onStartSession: () -> Void
    let onLogSession: () -> Void

    @Environment(\.marginTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if isExpanded {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.spring(duration: 0.3)) { isExpanded = false } }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Dismiss menu")
            }

            VStack(spacing: 12) {
                if isExpanded {
                    Button("Start Timed Session", systemImage: "timer") {
                        withAnimation(.spring(duration: 0.3)) { isExpanded = false }
                        onStartSession()
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .frame(width: 48, height: 48)
                    .contentShape(Circle())
                    .background(Circle().fill(theme.accent))
                    .foregroundStyle(theme.surface)
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))

                    Button("Log Session", systemImage: "pencil.line") {
                        withAnimation(.spring(duration: 0.3)) { isExpanded = false }
                        onLogSession()
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .frame(width: 48, height: 48)
                    .contentShape(Circle())
                    .background(Circle().fill(theme.accent))
                    .foregroundStyle(theme.surface)
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }

                Button(isExpanded ? "Close Menu" : "New Session", systemImage: isExpanded ? "xmark" : "pencil.line") {
                    withAnimation(.spring(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .font(.system(size: 22))
                .foregroundStyle(theme.surface)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(theme.accent)
                        .shadow(color: theme.fabShadowColor, radius: theme.fabShadowRadius, y: theme.fabShadowY)
                )
                .rotationEffect(.degrees(!reduceMotion && isExpanded ? 90 : 0))
                .animation(reduceMotion ? nil : .spring(duration: 0.3), value: isExpanded)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
    }
}
