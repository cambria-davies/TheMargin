import SwiftData

enum MarginSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Project.self, Session.self, WritingTip.self]
    }
}

enum MarginSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Project.self, Session.self, WritingTip.self]
    }
}

enum MarginMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [MarginSchemaV1.self, MarginSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    // Custom migration: promote wordCountGoal from optional to required.
    // Explicitly sets wordCountGoal to 0 for any projects where it was nil/zero.
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: MarginSchemaV1.self,
        toVersion: MarginSchemaV2.self,
        willMigrate: { context in
            let projects = try context.fetch(FetchDescriptor<Project>())
            for project in projects {
                if project.wordCountGoal == 0 {
                    project.wordCountGoal = 0
                }
            }
            try context.save()
        },
        didMigrate: nil
    )
}
