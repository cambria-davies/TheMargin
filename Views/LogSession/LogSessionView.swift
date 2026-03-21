import SwiftUI
import SwiftData

struct LogSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var wordCountSize: Double = 42
    @Query(filter: #Predicate<Project> { !$0.isArchived })
    private var projects: [Project]

    @AppStorage("lastUsedProjectID") private var lastUsedProjectID: String = ""
    @State private var vm = LogSessionViewModel()
    @State private var selectedProjectID: String = ""
    @State private var saveErrorMessage: String?
    @State private var showSaveError = false
    @FocusState private var wordCountFocused: Bool

    // Pan-to-dismiss state
    @State private var dragOffsetY: CGFloat = 0
    @State private var isDragging: Bool = false

    private static let dismissOffsetThreshold: CGFloat = 160
    private static let dismissVelocityThreshold: CGFloat = 800

    var editingSession: Session? = nil
    var prefilledDuration: Int?
    var onSave: ((Int) -> Void)?

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
                    TextField("0", text: $vm.wordCountText, prompt: Text("0").foregroundStyle(MarginTheme.inkLight))
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
                    TextField("Chapter or section (optional)", text: $vm.chapterTag, prompt: Text("Chapter or section (optional)").foregroundStyle(MarginTheme.inkLight))
                        .font(.typewriter(14))
                        .foregroundStyle(MarginTheme.inkBlack)
                        .padding(.horizontal, 48)
                        .padding(.top, 20)

                    // Mood selector
                    MoodSelectorView(selected: $vm.selectedMood)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)

                    // Notes
                    TextField("Notes...", text: $vm.notes, prompt: Text("Notes...").foregroundStyle(MarginTheme.inkLight), axis: .vertical)
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
                                let wordCount = vm.parsedWordCount ?? 0
                                try vm.save(project: project, editing: editingSession, context: modelContext)
                                lastUsedProjectID = project.id.uuidString
                                onSave?(wordCount)
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
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MarginTheme.inkLight)
                }
            }
        }
        .paperSurface(ruledLines: true, redMargin: true)
        .offset(y: reduceMotion ? 0 : max(0, dragOffsetY))
        .rotationEffect(
            reduceMotion ? .zero : .degrees(Double(dragOffsetY) * 0.018),
            anchor: .bottom
        )
        .gesture(
            reduceMotion ? nil : DragGesture(minimumDistance: 12, coordinateSpace: .global)
                .onChanged { value in
                    // Only track downward drags
                    let translation = value.translation.height
                    if translation > 0 {
                        isDragging = true
                        // Apply rubber-band resistance as drag grows
                        dragOffsetY = translation
                    }
                }
                .onEnded { value in
                    isDragging = false
                    let translation = value.translation.height
                    let velocity = value.velocity.height

                    let shouldDismiss = translation > Self.dismissOffsetThreshold
                        || velocity > Self.dismissVelocityThreshold

                    if shouldDismiss {
                        // Fly off bottom — longer duration for fast fling, shorter for threshold hit
                        let flyDuration: Double = velocity > Self.dismissVelocityThreshold ? 0.22 : 0.32
                        withAnimation(.easeIn(duration: flyDuration)) {
                            dragOffsetY = 900
                        }
                        Task {
                            // Give the fly-off animation a moment to start before dismissing
                            try? await Task.sleep(for: .milliseconds(Int(flyDuration * 600)))
                            dismiss()
                        }
                    } else {
                        // Spring back to resting position
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            dragOffsetY = 0
                        }
                    }
                }
        )
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: isDragging)
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
