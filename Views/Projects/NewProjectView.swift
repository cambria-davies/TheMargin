import SwiftUI
import SwiftData

struct NewProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var editingProject: Project?

    @State private var name: String = ""
    @State private var goalText: String = ""
    @State private var startingText: String = "0"
    @State private var isArchived: Bool = false
    @State private var saveErrorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PROJECT NAME")
                            .font(.literata(9, weight: .medium))
                            .foregroundStyle(MarginTheme.inkLight)
                            .tracking(1)
                        TextField("e.g. My Novel", text: $name)
                            .font(.typewriter(18))
                            .foregroundStyle(MarginTheme.inkBlack)
                    }
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("WORD COUNT GOAL (OPTIONAL)")
                            .font(.literata(9, weight: .medium))
                            .foregroundStyle(MarginTheme.inkLight)
                            .tracking(1)
                        TextField("e.g. 80000", text: $goalText)
                            .font(.typewriter(16))
                            .foregroundStyle(MarginTheme.inkBlack)
                            .keyboardType(.numberPad)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("WORDS ALREADY WRITTEN")
                            .font(.literata(9, weight: .medium))
                            .foregroundStyle(MarginTheme.inkLight)
                            .tracking(1)
                        TextField("0", text: $startingText)
                            .font(.typewriter(16))
                            .foregroundStyle(MarginTheme.inkBlack)
                            .keyboardType(.numberPad)
                    }

                    if editingProject != nil {
                        Toggle("Archived", isOn: $isArchived)
                            .font(.literata(14))
                            .foregroundStyle(MarginTheme.inkMedium)
                    }
                }
                .padding(.horizontal, 48)
            }
            .paperSurface()
            .navigationTitle(editingProject == nil ? "New Project" : "Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let project = editingProject {
                    name = project.name
                    goalText = project.wordCountGoal > 0 ? String(project.wordCountGoal) : ""
                    startingText = String(project.startingWordCount)
                    isArchived = project.isArchived
                }
            }
            .alert("Couldn't Save Project", isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage ?? "Unknown save error")
            }
        }
    }

    private func save() {
        let goal = Int(goalText.replacing(",", with: "")) ?? 0
        let starting = Int(startingText.replacing(",", with: "")) ?? 0

        do {
            if let project = editingProject {
                project.name = name
                project.wordCountGoal = goal
                project.startingWordCount = starting
                project.isArchived = isArchived
            } else {
                let project = Project(
                    name: name,
                    wordCountGoal: goal,
                    startingWordCount: starting
                )
                modelContext.insert(project)
            }
            try modelContext.save()
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}
