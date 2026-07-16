import Foundation
import LifePilotCore
import SwiftData

/// Model-backed repository used by SwiftData store facades.
@ModelActor
public actor LifePilotModelActor {
    public func fetchTasks() throws -> [TaskItem] {
        let descriptor = FetchDescriptor<PersistedTaskEntity>(
            sortBy: [SortDescriptor(\.dueDate, order: .forward)]
        )
        return try modelContext.fetch(descriptor).map { $0.asDomain() }
    }

    public func saveTask(_ task: TaskItem) throws {
        let targetID = task.id
        let descriptor = FetchDescriptor<PersistedTaskEntity>(
            predicate: #Predicate { $0.id == targetID }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(task)
        } else {
            modelContext.insert(PersistedTaskEntity(from: task))
        }
        try modelContext.save()
    }

    public func deleteTask(id: UUID) throws {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedTaskEntity>(
            predicate: #Predicate { $0.id == targetID }
        )
        for entity in try modelContext.fetch(descriptor) {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }

    public func fetchEvents() throws -> [CalendarEvent] {
        let descriptor = FetchDescriptor<PersistedEventEntity>(
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )
        return try modelContext.fetch(descriptor).map { $0.asDomain() }
    }

    public func saveEvent(_ event: CalendarEvent) throws {
        let targetID = event.id
        let descriptor = FetchDescriptor<PersistedEventEntity>(
            predicate: #Predicate { $0.id == targetID }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(event)
        } else {
            modelContext.insert(PersistedEventEntity(from: event))
        }
        try modelContext.save()
    }

    public func deleteEvent(id: UUID) throws {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedEventEntity>(
            predicate: #Predicate { $0.id == targetID }
        )
        for entity in try modelContext.fetch(descriptor) {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }

    public func loadPreferences() throws -> UserPreferences {
        let descriptor = FetchDescriptor<PersistedPreferenceEntity>(
            predicate: #Predicate { $0.singletonKey == "preferences" }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            return existing.asDomain()
        }
        return UserPreferences()
    }

    public func savePreferences(_ preferences: UserPreferences) throws {
        let descriptor = FetchDescriptor<PersistedPreferenceEntity>(
            predicate: #Predicate { $0.singletonKey == "preferences" }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(preferences)
        } else {
            modelContext.insert(PersistedPreferenceEntity(preferences: preferences))
        }
        try modelContext.save()
    }

    public func fetchMemory() throws -> [MemoryItem] {
        let descriptor = FetchDescriptor<PersistedMemoryEntity>()
        return try modelContext.fetch(descriptor).compactMap { $0.asDomain() }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    public func saveMemory(_ item: MemoryItem) throws {
        let targetID = item.id
        let descriptor = FetchDescriptor<PersistedMemoryEntity>(
            predicate: #Predicate { $0.id == targetID }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(item)
        } else {
            modelContext.insert(PersistedMemoryEntity(from: item))
        }
        try modelContext.save()
    }

    public func deleteMemory(id: UUID) throws {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedMemoryEntity>(
            predicate: #Predicate { $0.id == targetID }
        )
        for entity in try modelContext.fetch(descriptor) {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }

    public func deleteAllLifePilotOwnedData() throws {
        try deleteAll(PersistedTaskEntity.self)
        try deleteAll(PersistedEventEntity.self)
        try deleteAll(PersistedMemoryEntity.self)
        try deleteAll(PersistedApprovalEntity.self)
        try deleteAll(PersistedAuditEntity.self)
        try deleteAll(PersistedPreferenceEntity.self)
        try modelContext.save()
    }

    public func exportPayload() throws -> Data {
        let payload = ExportBundle(
            preferences: try loadPreferences(),
            memory: try fetchMemory(),
            tasks: try fetchTasks(),
            events: try fetchEvents()
        )
        return try JSONEncoder().encode(payload)
    }

    public func saveApproval(proposal: ActionProposal, record: ApprovalRecord) throws {
        let targetID = record.id
        let descriptor = FetchDescriptor<PersistedApprovalEntity>(
            predicate: #Predicate { $0.id == targetID }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(proposal: proposal, record: record)
        } else {
            modelContext.insert(PersistedApprovalEntity(proposal: proposal, record: record))
        }
        try modelContext.save()
    }

    public func fetchApprovals() throws -> [(ActionProposal, ApprovalRecord)] {
        let descriptor = FetchDescriptor<PersistedApprovalEntity>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).compactMap { entity in
            guard let proposal = entity.proposal, let record = entity.record else { return nil }
            return (proposal, record)
        }
    }

    public func appendAudit(_ event: AuditEvent) throws {
        modelContext.insert(PersistedAuditEntity(from: event))
        try modelContext.save()
    }

    public func fetchAudit() throws -> [AuditEvent] {
        let descriptor = FetchDescriptor<PersistedAuditEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).compactMap { $0.asDomain() }
    }

    private func deleteAll<T: PersistentModel>(_: T.Type) throws {
        let descriptor = FetchDescriptor<T>()
        for entity in try modelContext.fetch(descriptor) {
            modelContext.delete(entity)
        }
    }

    private struct ExportBundle: Codable {
        var preferences: UserPreferences
        var memory: [MemoryItem]
        var tasks: [TaskItem]
        var events: [CalendarEvent]
    }
}

public struct SwiftDataTaskStore: TaskStore {
    private let actor: LifePilotModelActor

    public init(container: ModelContainer) {
        actor = LifePilotModelActor(modelContainer: container)
    }

    public func allTasks() async -> [TaskItem] {
        (try? await actor.fetchTasks()) ?? []
    }

    public func save(_ task: TaskItem) async throws {
        try await actor.saveTask(task)
    }

    public func delete(id: UUID) async throws {
        try await actor.deleteTask(id: id)
    }

    public func tasks(matching predicate: @Sendable (TaskItem) -> Bool) async -> [TaskItem] {
        await allTasks().filter(predicate)
    }
}

public struct SwiftDataEventStore: EventStore {
    private let actor: LifePilotModelActor

    public init(container: ModelContainer) {
        actor = LifePilotModelActor(modelContainer: container)
    }

    public func allEvents() async -> [CalendarEvent] {
        (try? await actor.fetchEvents()) ?? []
    }

    public func save(_ event: CalendarEvent) async throws {
        try await actor.saveEvent(event)
    }

    public func delete(id: UUID) async throws {
        try await actor.deleteEvent(id: id)
    }
}

public struct SwiftDataPreferenceStore: PreferenceStore {
    private let actor: LifePilotModelActor

    public init(container: ModelContainer) {
        actor = LifePilotModelActor(modelContainer: container)
    }

    public func loadPreferences() async -> UserPreferences {
        (try? await actor.loadPreferences()) ?? UserPreferences()
    }

    public func savePreferences(_ preferences: UserPreferences) async throws {
        try await actor.savePreferences(preferences)
    }

    public func allMemory() async -> [MemoryItem] {
        (try? await actor.fetchMemory()) ?? []
    }

    public func saveMemory(_ item: MemoryItem) async throws {
        try await actor.saveMemory(item)
    }

    public func deleteMemory(id: UUID) async throws {
        try await actor.deleteMemory(id: id)
    }

    public func exportAll() async throws -> Data {
        try await actor.exportPayload()
    }

    public func deleteAllLifePilotData() async throws {
        try await actor.deleteAllLifePilotOwnedData()
    }
}

public struct SwiftDataApprovalStore: ApprovalStore {
    private let actor: LifePilotModelActor

    public init(container: ModelContainer) {
        actor = LifePilotModelActor(modelContainer: container)
    }

    public func save(proposal: ActionProposal, record: ApprovalRecord) async throws {
        try await actor.saveApproval(proposal: proposal, record: record)
    }

    public func all() async -> [(ActionProposal, ApprovalRecord)] {
        (try? await actor.fetchApprovals()) ?? []
    }

    public func appendAudit(_ event: AuditEvent) async throws {
        try await actor.appendAudit(event)
    }

    public func auditTrail() async -> [AuditEvent] {
        (try? await actor.fetchAudit()) ?? []
    }
}
