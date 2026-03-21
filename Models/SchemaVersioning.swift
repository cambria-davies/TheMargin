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

    // Lightweight migration: promote wordCountGoal from optional to required.
    // SwiftData assigns default 0 for any NULL values.
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: MarginSchemaV1.self,
        toVersion: MarginSchemaV2.self
    )
}
