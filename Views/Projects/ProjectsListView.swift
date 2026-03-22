import SwiftUI
import SwiftData

struct ProjectsListView: View {
    @Environment(\.marginTheme) private var theme
    @Query(sort: \Project.createdAt) private var allProjects: [Project]
    @AppStorage("lastUsedProjectID") private var lastUsedProjectID: String = ""
    @State private var showNewProject = false
    @State private var showArchived = false

    private var activeProjects: [Project] { allProjects.filter { !$0.isArchived } }
    private var archivedProjects: [Project] { allProjects.filter { $0.isArchived } }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    Text("Projects")
                        .font(.display(20))
                        .foregroundStyle(theme.text)
                        .padding(.bottom, 4)
                        .accessibilityAddTraits(.isHeader)

                    ForEach(activeProjects) { project in
                        NavigationLink {
                            ProjectDetailView(project: project)
                        } label: {
                            ProjectCardView(project: project, isCurrent: project.id.uuidString == lastUsedProjectID)
                        }
                        .buttonStyle(.plain)
                    }
                    if !archivedProjects.isEmpty {
                        Button {
                            withAnimation { showArchived.toggle() }
                        } label: {
                            HStack {
                                Text("Archived")
                                    .font(.grotesk(12))
                                    .foregroundStyle(theme.textTertiary)
                                Text("\(archivedProjects.count)")
                                    .font(.mono(10))
                                    .foregroundStyle(theme.textTertiary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(theme.surfaceDark)
                                    .clipShape(.capsule)
                                Spacer()
                                Image(systemName: showArchived ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundStyle(theme.textTertiary)
                            }
                        }
                        .padding(.top, 16)
                        if showArchived {
                            ForEach(archivedProjects) { project in
                                NavigationLink {
                                    ProjectDetailView(project: project)
                                } label: {
                                    ProjectCardView(project: project, isCurrent: false)
                                        .opacity(0.6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("+ New") { showNewProject = true }
                        .font(.grotesk(12))
                        .foregroundStyle(theme.accent)
                }
            }
            .sheet(isPresented: $showNewProject) {
                NewProjectView()
            }
        }
    }
}
