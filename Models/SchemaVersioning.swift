import SwiftData

enum MarginSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Project.self, Session.self, WritingTip.self]
    }
}

enum MarginMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [MarginSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
