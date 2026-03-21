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

enum WelcomeField: Hashable {
    case name, goal
}

// MARK: - WelcomeView

struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.marginTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onComplete: () -> Void

    // Animation state
    @State private var phase: WelcomePhase = .initial

    // Form state
    @State private var projectName: String = ""
    @State private var wordCountGoalText: String = ""
    @State private var nameInvalid: Bool = false
    @State private var goalInvalid: Bool = false

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
                        goalWords: 80000,
                        size: .compact,
                        showGlow: false,
                        animated: false
                    )
                    .padding(.top, 60)
                    .opacity(showStack ? 1 : 0)
                    .scaleEffect(showStack ? 1 : 0.85)
                    .animation(reduceMotion ? .none : .easeOut(duration: 0.6), value: showStack)

                    // Typed app name
                    TypewriterText(text: "The Margin", fontSize: 28)
                        .padding(.top, 28)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 8)
                        .animation(reduceMotion ? .none : .easeOut(duration: 0.3), value: showTitle)

                    // Atwood quote
                    VStack(spacing: 6) {
                        Text("\"A word after a word after a word is power.\"")
                            .font(.display(16, weight: .light))
                            .foregroundStyle(theme.textDim)
                            .multilineTextAlignment(.center)

                        Text("— Margaret Atwood")
                            .font(.literata(12))
                            .foregroundStyle(theme.textFaint)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 16)
                    .opacity(showQuote ? 1 : 0)
                    .animation(reduceMotion ? .none : .easeOut(duration: 0.5), value: showQuote)

                    // Project creation form
                    WelcomeFormSection(
                        projectName: $projectName,
                        wordCountGoalText: $wordCountGoalText,
                        nameInvalid: nameInvalid,
                        goalInvalid: goalInvalid,
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
                        .font(.literata(12))
                        .foregroundStyle(theme.textFaint)
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
        .onChange(of: wordCountGoalText) { _, _ in
            if goalInvalid { goalInvalid = false }
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

        guard let parsedGoal = Int(trimmedGoal), parsedGoal > 0 else {
            goalInvalid = true
            focusedField = .goal
            return
        }

        let cappedGoal = min(parsedGoal, 10_000_000)
        let project = Project(name: trimmedName, wordCountGoal: cappedGoal)
        modelContext.insert(project)

        do {
            try modelContext.save()
        } catch {
            // SwiftData will autosave; proceed regardless
        }

        UserDefaults.standard.set(true, forKey: "hasCompletedWelcome")
        UserDefaults.standard.set(project.id.uuidString, forKey: "lastUsedProjectID")

        onComplete()
    }
}

// MARK: - WelcomeFormSection

private struct WelcomeFormSection: View {
    @Binding var projectName: String
    @Binding var wordCountGoalText: String
    let nameInvalid: Bool
    let goalInvalid: Bool
    var focusedField: FocusState<WelcomeField?>.Binding
    let onSubmit: () -> Void
    let theme: MarginTheme

    var body: some View {
        VStack(spacing: 20) {
            // Project name field
            VStack(alignment: .leading, spacing: 6) {
                Text("PROJECT NAME")
                    .font(.literata(10, weight: .medium))
                    .foregroundStyle(theme.textFaint)
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
                            .fill(nameInvalid ? theme.amber : theme.textFaint.opacity(0.3))
                            .frame(height: nameInvalid ? 2 : 1)
                            .animation(.easeInOut(duration: 0.2), value: nameInvalid)
                    }
            }

            // Word count goal field
            VStack(alignment: .leading, spacing: 6) {
                Text("WORD COUNT GOAL")
                    .font(.literata(10, weight: .medium))
                    .foregroundStyle(theme.textFaint)
                    .tracking(2)

                TextField("80000", text: $wordCountGoalText)
                    .font(.mono(16))
                    .foregroundStyle(theme.text)
                    .keyboardType(.numberPad)
                    .focused(focusedField, equals: .goal)
                    .submitLabel(.done)
                    .onSubmit { onSubmit() }
                    .padding(.bottom, 8)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(goalInvalid ? theme.amber : theme.textFaint.opacity(0.3))
                            .frame(height: goalInvalid ? 2 : 1)
                            .animation(.easeInOut(duration: 0.2), value: goalInvalid)
                    }
            }

            // Submit button
            Button(action: onSubmit) {
                Text("BEGIN WRITING")
                    .font(.typewriter(15))
                    .foregroundStyle(MarginTheme.paper)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(MarginTheme.inkBlack)
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
