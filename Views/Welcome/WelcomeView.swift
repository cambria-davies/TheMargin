import SwiftUI
import SwiftData

// MARK: - Animation Phase

private enum WelcomePhase: Int, Comparable {
    case initial = 0
    case stackLanding = 1
    case titleTyping = 2
    case quoteFade = 3
    case formReveal = 4
    case ready = 5

    static func < (lhs: WelcomePhase, rhs: WelcomePhase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Focus Field

private enum WelcomeField: Hashable {
    case name, goal, startingWordCount
}

// MARK: - WelcomeView

struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.marginTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onComplete: () -> Void

    @AppStorage("hasCompletedWelcome") private var hasCompletedWelcome = false
    @AppStorage("lastUsedProjectID") private var lastUsedProjectID = ""

    // Animation state
    @State private var phase: WelcomePhase = .initial

    // Form state
    @State private var projectName: String = ""
    @State private var wordCountGoalText: String = ""
    @State private var startingWordCountText: String = ""
    @State private var nameInvalid: Bool = false

    // Focus
    @FocusState private var focusedField: WelcomeField?

    // Visibility computed from phase (or reduce motion)
    private var showStack: Bool { reduceMotion || phase >= .stackLanding }
    private var showTitle: Bool { reduceMotion || phase >= .titleTyping }
    private var showQuote: Bool { reduceMotion || phase >= .quoteFade }
    private var showForm: Bool  { reduceMotion || phase >= .formReveal }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Manuscript stack preview
                    ManuscriptStackView(
                        totalWords: 1250,
                        size: .compact,
                        showGlow: false,
                        animated: false
                    )
                    .padding(.top, 60)
                    .opacity(showStack ? 1 : 0)
                    .scaleEffect(showStack ? 1 : 0.85)
                    .animation(reduceMotion ? .none : .easeOut(duration: 0.6), value: showStack)

                    // Typed app name
                    TypewriterText(text: "The Margin", fontSize: 28, onPaper: false)
                        .padding(.top, 28)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 8)
                        .animation(reduceMotion ? .none : .easeOut(duration: 0.3), value: showTitle)

                    // Atwood quote
                    VStack(spacing: 6) {
                        Text("\"A word after a word after a word is power.\"")
                            .font(.display(16, weight: .light))
                            .foregroundStyle(theme.textSecondary)
                            .multilineTextAlignment(.center)

                        Text("— Margaret Atwood")
                            .font(.grotesk(12))
                            .foregroundStyle(theme.textTertiary)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 16)
                    .opacity(showQuote ? 1 : 0)
                    .animation(reduceMotion ? .none : .easeOut(duration: 0.5), value: showQuote)

                    // Project creation form
                    WelcomeFormSection(
                        projectName: $projectName,
                        wordCountGoalText: $wordCountGoalText,
                        startingWordCountText: $startingWordCountText,
                        nameInvalid: nameInvalid,
                        focusedField: $focusedField,
                        onSubmit: handleSubmit,
                        theme: theme
                    )
                    .padding(.top, 36)
                    .padding(.horizontal, 32)
                    .opacity(showForm ? 1 : 0)
                    .offset(y: showForm ? 0 : 12)
                    .animation(reduceMotion ? .none : .easeOut(duration: 0.3), value: showForm)

                    // Footer note
                    Text("You can always add more projects later.")
                        .font(.grotesk(12))
                        .foregroundStyle(theme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 16)
                        .padding(.bottom, 48)
                        .opacity(showForm ? 1 : 0)
                        .animation(
                            reduceMotion ? .none : .easeOut(duration: 0.3).delay(0.1),
                            value: showForm
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .task {
            await runChoreography()
        }
        .onChange(of: projectName) { _, _ in
            if nameInvalid { nameInvalid = false }
        }
    }

    // MARK: - Choreography

    private func runChoreography() async {
        guard !reduceMotion else {
            phase = .ready
            focusedField = .name
            return
        }

        try? await Task.sleep(for: .milliseconds(300))
        withAnimation { phase = .stackLanding }

        try? await Task.sleep(for: .milliseconds(700))
        withAnimation { phase = .titleTyping }

        try? await Task.sleep(for: .milliseconds(400))
        withAnimation { phase = .quoteFade }

        try? await Task.sleep(for: .milliseconds(600))
        withAnimation { phase = .formReveal }

        try? await Task.sleep(for: .milliseconds(400))
        phase = .ready
        focusedField = .name
    }

    // MARK: - Submission

    private func handleSubmit() {
        let trimmedName = projectName.trimmingCharacters(in: .whitespaces)
        let trimmedGoal = wordCountGoalText.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty, trimmedName.count <= 100 else {
            nameInvalid = true
            focusedField = .name
            return
        }

        let parsedGoal = Int(trimmedGoal.replacing(",", with: "")) ?? 0
        let cappedGoal = min(max(parsedGoal, 0), 10_000_000)

        let trimmedStarting = startingWordCountText.trimmingCharacters(in: .whitespaces)
        let parsedStarting = Int(trimmedStarting.replacing(",", with: "")) ?? 0
        let cappedStarting = min(max(parsedStarting, 0), 10_000_000)

        let project = Project(name: trimmedName, wordCountGoal: cappedGoal, startingWordCount: cappedStarting)
        modelContext.insert(project)

        do {
            try modelContext.save()
        } catch {
            // SwiftData will autosave; proceed regardless
        }

        hasCompletedWelcome = true
        lastUsedProjectID = project.id.uuidString

        onComplete()
    }
}

// MARK: - WelcomeFormSection

private struct WelcomeFormSection: View {
    @Binding var projectName: String
    @Binding var wordCountGoalText: String
    @Binding var startingWordCountText: String
    let nameInvalid: Bool
    var focusedField: FocusState<WelcomeField?>.Binding
    let onSubmit: () -> Void
    let theme: MarginTheme

    var body: some View {
        VStack(spacing: 20) {
            // Project name field
            VStack(alignment: .leading, spacing: 6) {
                Text("PROJECT NAME")
                    .font(.mono(10, weight: .semibold))
                    .foregroundStyle(theme.textTertiary)
                    .tracking(2)

                TextField("My Novel", text: $projectName)
                    .font(.typewriter(16))
                    .foregroundStyle(theme.text)
                    .focused(focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focusedField.wrappedValue = .goal }
                    .padding(.bottom, 8)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(nameInvalid ? theme.accent : theme.textTertiary.opacity(0.3))
                            .frame(height: nameInvalid ? 2 : 1)
                            .animation(.easeInOut(duration: 0.2), value: nameInvalid)
                    }
            }

            // Word count goal field
            VStack(alignment: .leading, spacing: 6) {
                Text("WORD COUNT GOAL")
                    .font(.mono(10, weight: .semibold))
                    .foregroundStyle(theme.textTertiary)
                    .tracking(2)

                TextField("80,000 (optional)", text: $wordCountGoalText)
                    .font(.mono(16))
                    .foregroundStyle(theme.text)
                    .keyboardType(.numberPad)
                    .focused(focusedField, equals: .goal)
                    .submitLabel(.next)
                    .onSubmit { focusedField.wrappedValue = .startingWordCount }
                    .padding(.bottom, 8)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(theme.textTertiary.opacity(0.3))
                            .frame(height: 1)
                    }
            }

            // Starting word count field
            VStack(alignment: .leading, spacing: 6) {
                Text("STARTING WORD COUNT")
                    .font(.mono(10, weight: .semibold))
                    .foregroundStyle(theme.textTertiary)
                    .tracking(2)

                TextField("0 (optional)", text: $startingWordCountText)
                    .font(.mono(16))
                    .foregroundStyle(theme.text)
                    .keyboardType(.numberPad)
                    .focused(focusedField, equals: .startingWordCount)
                    .submitLabel(.done)
                    .onSubmit { onSubmit() }
                    .padding(.bottom, 8)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(theme.textTertiary.opacity(0.3))
                            .frame(height: 1)
                    }
            }

            // Submit button
            Button(action: onSubmit) {
                Text("BEGIN WRITING")
                    .font(.typewriter(15))
                    .foregroundStyle(theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.accent)
                    .clipShape(.rect(cornerRadius: 6))
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeView(onComplete: {})
        .modelContainer(for: [Project.self, Session.self], inMemory: true)
}
