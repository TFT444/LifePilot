import Foundation
import LifePilotCore
import SwiftData

// SwiftData entities for LifePilot-owned records. Domain structs in Core stay
// framework-agnostic; these models are the on-disk representation.

@Model
public final class PersistedTaskEntity {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var notes: String?
    public var dueDate: Date?
    public var startDate: Date?
    public var isCompleted: Bool
    public var completedAt: Date?
    public var priorityRaw: String
    public var tagsJSON: Data
    public var listID: UUID?
    public var parentID: UUID?
    public var estimatedDuration: Double?
    public var contextRaw: String
    public var recurrenceJSON: Data?
    public var sourceRaw: String
    public var externalIdentifier: String?
    public var syncStateRaw: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(from task: TaskItem) {
        id = task.id
        title = task.title
        notes = task.notes
        dueDate = task.dueDate
        startDate = task.startDate
        isCompleted = task.isCompleted
        completedAt = task.completedAt
        priorityRaw = task.priority.rawValue
        tagsJSON = PersistenceCoding.encode(task.tags)
        listID = task.listID
        parentID = task.parentID
        estimatedDuration = task.estimatedDuration
        contextRaw = task.context.rawValue
        recurrenceJSON = task.recurrence.map { PersistenceCoding.encode($0) }
        sourceRaw = task.source.rawValue
        externalIdentifier = task.externalIdentifier
        syncStateRaw = task.syncState.rawValue
        createdAt = task.createdAt
        updatedAt = task.updatedAt
    }

    public func apply(_ task: TaskItem) {
        title = task.title
        notes = task.notes
        dueDate = task.dueDate
        startDate = task.startDate
        isCompleted = task.isCompleted
        completedAt = task.completedAt
        priorityRaw = task.priority.rawValue
        tagsJSON = PersistenceCoding.encode(task.tags)
        listID = task.listID
        parentID = task.parentID
        estimatedDuration = task.estimatedDuration
        contextRaw = task.context.rawValue
        recurrenceJSON = task.recurrence.map { PersistenceCoding.encode($0) }
        sourceRaw = task.source.rawValue
        externalIdentifier = task.externalIdentifier
        syncStateRaw = task.syncState.rawValue
        createdAt = task.createdAt
        updatedAt = task.updatedAt
    }

    public func asDomain() -> TaskItem {
        TaskItem(
            id: id,
            title: title,
            notes: notes,
            dueDate: dueDate,
            startDate: startDate,
            isCompleted: isCompleted,
            completedAt: completedAt,
            priority: TaskItem.Priority(rawValue: priorityRaw) ?? .normal,
            tags: PersistenceCoding.decode([String].self, from: tagsJSON) ?? [],
            listID: listID,
            parentID: parentID,
            estimatedDuration: estimatedDuration,
            context: LifeContext(rawValue: contextRaw) ?? .personal,
            recurrence: recurrenceJSON.flatMap { PersistenceCoding.decode(RecurrenceRule.self, from: $0) },
            source: DataSource(rawValue: sourceRaw) ?? .local,
            externalIdentifier: externalIdentifier,
            syncState: SyncState(rawValue: syncStateRaw) ?? .localOnly,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

@Model
public final class PersistedEventEntity {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var notes: String?
    public var location: String?
    public var startDate: Date
    public var endDate: Date
    public var isAllDay: Bool
    public var attendeeCount: Int
    public var contextRaw: String
    public var eventKindRaw: String
    public var preparationMinutes: Int
    public var travelBufferMinutes: Int
    public var recurrenceJSON: Data?
    public var sourceRaw: String
    public var externalIdentifier: String?
    public var syncStateRaw: String
    public var statusRaw: String

    public init(from event: CalendarEvent) {
        id = event.id
        title = event.title
        notes = event.notes
        location = event.location
        startDate = event.startDate
        endDate = event.endDate
        isAllDay = event.isAllDay
        attendeeCount = event.attendeeCount
        contextRaw = event.context.rawValue
        eventKindRaw = event.eventKind.rawValue
        preparationMinutes = event.preparationMinutes
        travelBufferMinutes = event.travelBufferMinutes
        recurrenceJSON = event.recurrence.map { PersistenceCoding.encode($0) }
        sourceRaw = event.source.rawValue
        externalIdentifier = event.externalIdentifier
        syncStateRaw = event.syncState.rawValue
        statusRaw = event.status.rawValue
    }

    public func apply(_ event: CalendarEvent) {
        title = event.title
        notes = event.notes
        location = event.location
        startDate = event.startDate
        endDate = event.endDate
        isAllDay = event.isAllDay
        attendeeCount = event.attendeeCount
        contextRaw = event.context.rawValue
        eventKindRaw = event.eventKind.rawValue
        preparationMinutes = event.preparationMinutes
        travelBufferMinutes = event.travelBufferMinutes
        recurrenceJSON = event.recurrence.map { PersistenceCoding.encode($0) }
        sourceRaw = event.source.rawValue
        externalIdentifier = event.externalIdentifier
        syncStateRaw = event.syncState.rawValue
        statusRaw = event.status.rawValue
    }

    public func asDomain() -> CalendarEvent {
        CalendarEvent(
            id: id,
            title: title,
            notes: notes,
            location: location,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            attendeeCount: attendeeCount,
            context: LifeContext(rawValue: contextRaw) ?? .personal,
            eventKind: EventKind(rawValue: eventKindRaw) ?? .personal,
            preparationMinutes: preparationMinutes,
            travelBufferMinutes: travelBufferMinutes,
            recurrence: recurrenceJSON.flatMap { PersistenceCoding.decode(RecurrenceRule.self, from: $0) },
            source: DataSource(rawValue: sourceRaw) ?? .local,
            externalIdentifier: externalIdentifier,
            syncState: SyncState(rawValue: syncStateRaw) ?? .localOnly,
            status: AttendanceStatus(rawValue: statusRaw) ?? .confirmed
        )
    }
}

@Model
public final class PersistedPreferenceEntity {
    @Attribute(.unique) public var singletonKey: String
    public var payloadJSON: Data

    public init(preferences: UserPreferences) {
        singletonKey = "preferences"
        payloadJSON = PersistenceCoding.encode(preferences)
    }

    public func apply(_ preferences: UserPreferences) {
        payloadJSON = PersistenceCoding.encode(preferences)
    }

    public func asDomain() -> UserPreferences {
        PersistenceCoding.decode(UserPreferences.self, from: payloadJSON) ?? UserPreferences()
    }
}

@Model
public final class PersistedMemoryEntity {
    @Attribute(.unique) public var id: UUID
    public var payloadJSON: Data

    public init(from item: MemoryItem) {
        id = item.id
        payloadJSON = PersistenceCoding.encode(item)
    }

    public func apply(_ item: MemoryItem) {
        payloadJSON = PersistenceCoding.encode(item)
    }

    public func asDomain() -> MemoryItem? {
        PersistenceCoding.decode(MemoryItem.self, from: payloadJSON)
    }
}

@Model
public final class PersistedApprovalEntity {
    @Attribute(.unique) public var id: UUID
    public var proposalJSON: Data
    public var recordJSON: Data
    public var updatedAt: Date

    public init(proposal: ActionProposal, record: ApprovalRecord) {
        id = record.id
        proposalJSON = PersistenceCoding.encode(proposal)
        recordJSON = PersistenceCoding.encode(record)
        updatedAt = Date()
    }

    public func apply(proposal: ActionProposal, record: ApprovalRecord) {
        proposalJSON = PersistenceCoding.encode(proposal)
        recordJSON = PersistenceCoding.encode(record)
        updatedAt = Date()
    }

    public var proposal: ActionProposal? {
        PersistenceCoding.decode(ActionProposal.self, from: proposalJSON)
    }

    public var record: ApprovalRecord? {
        PersistenceCoding.decode(ApprovalRecord.self, from: recordJSON)
    }
}

@Model
public final class PersistedAuditEntity {
    @Attribute(.unique) public var id: UUID
    public var payloadJSON: Data
    public var createdAt: Date

    public init(from event: AuditEvent) {
        id = event.id
        payloadJSON = PersistenceCoding.encode(event)
        createdAt = event.timestamp
    }

    public func asDomain() -> AuditEvent? {
        PersistenceCoding.decode(AuditEvent.self, from: payloadJSON)
    }
}

enum PersistenceCoding {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func encode(_ value: some Encodable) -> Data {
        (try? encoder.encode(value)) ?? Data()
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        guard !data.isEmpty else { return nil }
        return try? decoder.decode(type, from: data)
    }
}
