import SwiftUI
import SwiftData

@main
struct TheMarginApp: App {
    let container: ModelContainer
    private let containerError: Error?

    init() {
        do {
            let schema = Schema([Project.self, Session.self, WritingTip.self])
            let configuration = ModelConfiguration(schema: schema)
            let c = try ModelContainer(for: schema, migrationPlan: MarginMigrationPlan.self, configurations: [configuration])
            container = c
            containerError = nil
            Self.seedTipsIfNeeded(context: c.mainContext)
        } catch {
            // Fallback to in-memory container so the app can launch and show an error
            let fallback = try! ModelContainer(for: Schema([Project.self, Session.self, WritingTip.self]),
                                               configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
            container = fallback
            containerError = error
        }
    }

    var body: some Scene {
        WindowGroup {
            if let error = containerError {
                DatabaseErrorView(error: error)
            } else {
                ContentView()
            }
        }
        .modelContainer(container)
    }

    static func seedTipsIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<WritingTip>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        guard let url = Bundle.main.url(forResource: "writing-tips", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }

        struct TipJSON: Decodable {
            let type: String
            let text: String
            let author: String?
            let source: String?
            let tags: [String]
        }

        guard let tips = try? JSONDecoder().decode([TipJSON].self, from: data) else { return }
        for tip in tips {
            let category = TipCategory(rawValue: tip.type == "quote" ? "quote" : "craft") ?? .craft
            let attribution = [tip.author, tip.source].compactMap { $0 }.joined(separator: " — ")
            context.insert(
                WritingTip(
                    text: tip.text,
                    attribution: attribution.isEmpty ? nil : attribution,
                    category: category
                )
            )
        }
        try? context.save()
    }
}
