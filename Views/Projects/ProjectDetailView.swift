import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @Environment(\.marginTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @State private var showEditProject = false
    @State private var sessionPendingDelete: Session?
    @State private var deleteErrorMessage: String?
    @State private var editingSession: Session?

    private var sortedSessions: [Session] {
        project.sessions.sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(project.name)
                    .font(.display(22))
                    .foregroundStyle(theme.text)
                    .padding(.horizontal, 24)

                HStack(alignment: .top, spacing: 20) {
                    ManuscriptStackView(totalWords: project.totalWords, goalWords: project.wordCountGoal, size: .compact)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(project.totalWords) words")
                            .font(.display(20))
                            .foregroundStyle(theme.text)
                        Text("\(project.sessions.count) sessions")
                            .font(.literata(13))
                            .foregroundStyle(theme.textDim)
                        if project.wordCountGoal > 0 {
                            ProgressView(value: project.goalProgress)
                                .tint(theme.amber)
                            if let projected = InsightsCalculator.projectedCompletionDate(for: project) {
                                Text("Projected: \(projected, style: .date)")
                                    .font(.literata(11))
                                    .foregroundStyle(theme.textDim)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                if sortedSessions.isEmpty {
                    EmptySessionPageView()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: -24) {
                        ForEach(Array(sortedSessions.enumerated()), id: \.element.id) { index, session in
                            Button {
                                editingSession = session
                            } label: {
                                SessionPageView(
                                    session: session,
                                    sessionNumber: sortedSessions.count - index,
                                    isToday: Calendar.current.isDateInToday(session.date),
                                    onRequestDelete: { sessionPendingDelete = session }
                                )
                            }
                            .buttonStyle(.plain)
                            .rotationEffect(.degrees(sin(Double(session.id.hashValue % 100) / 50.0) * 1.0))
                            .zIndex(Double(sortedSessions.count - index))
                            .accessibilityLabel("Session \(sortedSessions.count - index)")
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .background(theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditProject = true }
            }
        }
        .sheet(isPresented: $showEditProject) {
            NewProjectView(editingProject: project)
        }
        .sheet(item: $editingSession) { session in
            LogSessionView(editingSession: session)
        }
        .alert("Couldn't Delete Session", isPresented: Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage ?? "Unknown delete error")
        }
        .confirmationDialog(
            "Delete this session?",
            isPresented: Binding(
                get: { sessionPendingDelete != nil },
                set: { if !$0 { sessionPendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Session", role: .destructive) {
                guard let session = sessionPendingDelete else { return }
                do {
                    modelContext.delete(session)
                    try modelContext.save()
                    sessionPendingDelete = nil
                } catch {
                    deleteErrorMessage = error.localizedDescription
                }
            }
            Button("Cancel", role: .cancel) { sessionPendingDelete = nil }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
