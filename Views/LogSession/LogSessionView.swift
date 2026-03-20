import SwiftUI
import SwiftData

struct LogSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .largeTitle) private var wordCountSize: Double = 42
    @Query(filter: #Predicate<Project> { !$0.isArchived })
    private var projects: [Project]

    @AppStorage("lastUsedProjectID") private var lastUsedProjectID: String = ""
    @State private var vm = LogSessionViewModel()
    @State private var selectedProjectID: String = ""
    @State private var saveErrorMessage: String?
    @State private var showSaveError = false
    @FocusState private var wordCountFocused: Bool

    var editingSession: Session? = nil
    var prefilledDuration: Int?

    private var selectedProject: Project? {
        projects.first(where: { $0.id.uuidString == selectedProjectID })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Project stamp
                    HStack {
                        Menu {
                            ForEach(projects) { project in
                                Button(project.name) {
                                    selectedProjectID = project.id.uuidString
                                }
                            }
                        } label: {
                            Text(selectedProject?.name.uppercased() ?? "SELECT PROJECT")
                                .font(.typewriter(13))
                                .foregroundStyle(MarginTheme.inkLight)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(MarginTheme.inkLight.opacity(0.3), lineWidth: 1)
                                )
                                .rotationEffect(.degrees(-1))
                        }

                        Spacer()

                        // Duration pill (if from timer)
                        if let duration = vm.prefilledDurationSeconds {
                            Text(formatDuration(duration))
                                .font(.mono(11))
                                .foregroundStyle(MarginTheme.inkLight)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(MarginTheme.paperDark.opacity(0.5))
                                .clipShape(.capsule)
                        }
                    }
                    .padding(.horizontal, 48)
                    .padding(.top, 20)

                    // Word count (hero field)
                    TextField("0", text: $vm.wordCountText)
                        .font(.typewriter(wordCountSize))
                        .foregroundStyle(MarginTheme.inkBlack)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .focused($wordCountFocused)
                        .padding(.vertical, 24)
                        .padding(.horizontal, 48)

                    Text("WORDS")
                        .font(.literata(10, weight: .medium))
                        .foregroundStyle(MarginTheme.inkLight)
                        .tracking(2)
                        .frame(maxWidth: .infinity)

                    // Chapter tag
                    TextField("Chapter or section (optional)", text: $vm.chapterTag)
                        .font(.typewriter(14))
                        .foregroundStyle(MarginTheme.inkBlack)
                        .padding(.horizontal, 48)
                        .padding(.top, 20)

                    // Mood selector
                    MoodSelectorView(selected: $vm.selectedMood)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)

                    // Notes
                    TextField("Notes...", text: $vm.notes, axis: .vertical)
                        .font(.typewriter(13))
                        .foregroundStyle(MarginTheme.inkBlack)
                        .lineSpacing(15)
                        .lineLimit(3...8)
                        .padding(.horizontal, 48)
                        .padding(.bottom, 24)

                    // Save button
                    Button {
                        if let project = selectedProject {
                            do {
                                try vm.save(project: project, editing: editingSession, context: modelContext)
                                lastUsedProjectID = project.id.uuidString
                                dismiss()
                            } catch {
                                saveErrorMessage = error.localizedDescription
                                showSaveError = true
                            }
                        }
                    } label: {
                        Text(editingSession == nil ? "SAVE" : "UPDATE")
                            .font(.typewriter(14))
                            .foregroundStyle(MarginTheme.paper)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(MarginTheme.inkBlack)
                            .clipShape(.rect(cornerRadius: 6))
                    }
                    .disabled(!vm.canSave || selectedProject == nil)
                    .opacity(vm.canSave && selectedProject != nil ? 1.0 : 0.4)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .paperSurface()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MarginTheme.inkLight)
                }
            }
        }
        .onAppear {
            if let editingSession {
                selectedProjectID = editingSession.project?.id.uuidString ?? ""
                vm.wordCountText = String(editingSession.wordCount)
                vm.selectedMood = editingSession.mood
                vm.notes = editingSession.notes ?? ""
                vm.chapterTag = editingSession.chapterTag ?? ""
                vm.prefilledDurationSeconds = editingSession.durationSeconds
            } else {
                selectedProjectID = projects.contains(where: { $0.id.uuidString == lastUsedProjectID })
                    ? lastUsedProjectID
                    : (projects.first?.id.uuidString ?? "")
                vm.prefilledDurationSeconds = prefilledDuration
            }
            wordCountFocused = true
        }
        .alert("Couldn't Save Session", isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "Unknown save error")
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond(padMinuteToLength: 1)))
    }
}
