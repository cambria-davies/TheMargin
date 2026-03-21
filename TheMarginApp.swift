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
        Self.seedTipsIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
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
