import SwiftUI
import SwiftData

@main
struct TheMarginApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([Project.self, Session.self, WritingTip.self])
            let configuration = ModelConfiguration(schema: schema)
            container = try ModelContainer(for: schema, migrationPlan: MarginMigrationPlan.self, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
