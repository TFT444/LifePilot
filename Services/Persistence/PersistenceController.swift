import Foundation
import SwiftData

/// Owns the SwiftData `ModelContainer` for LifePilot-owned records.
public final class PersistenceController: @unchecked Sendable {
    public let container: ModelContainer
    public let isInMemory: Bool

    public static let shared: PersistenceController = {
        do {
            return try PersistenceController(inMemory: false)
        } catch {
            // Corrupt store / sandbox issues: fall back so the app still launches.
            return try! PersistenceController(inMemory: true)
        }
    }()

    public init(inMemory: Bool = false) throws {
        let schema = Schema([
            PersistedTaskEntity.self,
            PersistedEventEntity.self,
            PersistedPreferenceEntity.self,
            PersistedMemoryEntity.self,
            PersistedApprovalEntity.self,
            PersistedAuditEntity.self,
        ])
        let configuration = ModelConfiguration(
            "LifePilot",
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        container = try ModelContainer(for: schema, configurations: [configuration])
        self.isInMemory = inMemory
    }
}
