import Foundation
import LifePilotCore

/// In-memory task store for offline-first MVP and deterministic tests.
public actor InMemoryTaskStore: TaskStore {
    private var tasks: [UUID: TaskItem] = [:]

    public init(seed: [TaskItem] = []) {
        for task in seed {
            tasks[task.id] = task
        }
    }

    public func allTasks() async -> [TaskItem] {
        Array(tasks.values).sorted { lhs, rhs in
            (lhs.dueDate ?? .distantFuture) < (rhs.dueDate ?? .distantFuture)
        }
    }

    public func save(_ task: TaskItem) async throws {
        var copy = task
        copy.updatedAt = Date()
        tasks[copy.id] = copy
    }

    public func delete(id: UUID) async throws {
        guard tasks.removeValue(forKey: id) != nil else {
            throw DomainError.notFound
        }
    }

    public func tasks(matching predicate: @Sendable (TaskItem) -> Bool) async -> [TaskItem] {
        Array(tasks.values).filter(predicate)
    }
}

/// In-memory event store.
public actor InMemoryEventStore: EventStore {
    private var events: [UUID: CalendarEvent] = [:]

    public init(seed: [CalendarEvent] = []) {
        for event in seed {
            events[event.id] = event
        }
    }

    public func allEvents() async -> [CalendarEvent] {
        Array(events.values).sorted { $0.startDate < $1.startDate }
    }

    public func save(_ event: CalendarEvent) async throws {
        events[event.id] = event
    }

    public func delete(id: UUID) async throws {
        guard events.removeValue(forKey: id) != nil else {
            throw DomainError.notFound
        }
    }
}

/// In-memory preferences, memory, export, and wipe.
public actor InMemoryPreferenceStore: PreferenceStore {
    private var preferences: UserPreferences
    private var memory: [UUID: MemoryItem] = [:]

    public init(preferences: UserPreferences = UserPreferences()) {
        self.preferences = preferences
    }

    public func loadPreferences() async -> UserPreferences {
        preferences
    }

    public func savePreferences(_ preferences: UserPreferences) async throws {
        self.preferences = preferences
    }

    public func allMemory() async -> [MemoryItem] {
        Array(memory.values).sorted { $0.updatedAt > $1.updatedAt }
    }

    public func saveMemory(_ item: MemoryItem) async throws {
        var copy = item
        copy.updatedAt = Date()
        memory[copy.id] = copy
    }

    public func deleteMemory(id: UUID) async throws {
        guard memory.removeValue(forKey: id) != nil else {
            throw DomainError.notFound
        }
    }

    public func exportAll() async throws -> Data {
        let payload = ExportPayload(preferences: preferences, memory: Array(memory.values))
        return try JSONEncoder().encode(payload)
    }

    public func deleteAllLifePilotData() async throws {
        preferences = UserPreferences()
        memory.removeAll()
    }

    private struct ExportPayload: Codable {
        var preferences: UserPreferences
        var memory: [MemoryItem]
    }
}

/// No-op notification scheduler for unit tests and offline builds without
/// UserNotifications entitlements.
public struct NoOpNotificationScheduler: NotificationScheduling {
    public init() {}

    public func schedule(
        id _: String,
        title _: String,
        body _: String,
        fireDate _: Date
    ) async throws {
        // No-op for unit tests and entitlement-free builds.
    }

    public func cancel(id _: String) async throws {
        // No-op
    }
}

/// Builds a unified timeline from task and event stores.
public struct StoreBackedTimelineProvider: TimelineProviding {
    private let taskStore: any TaskStore
    private let eventStore: any EventStore

    public init(taskStore: any TaskStore, eventStore: any EventStore) {
        self.taskStore = taskStore
        self.eventStore = eventStore
    }

    public func loadEntries(relativeTo _: Date) async -> [TimelineEntry] {
        let events = await eventStore.allEvents().map {
            TimelineEntry(
                id: $0.id,
                date: $0.startDate,
                title: $0.title,
                subtitle: $0.location,
                kind: .event,
                context: $0.context,
                freshness: $0.syncState == .unavailable ? .unavailable : .live
            )
        }
        let tasks = await taskStore.allTasks().compactMap { task -> TimelineEntry? in
            guard let due = task.dueDate else { return nil }
            return TimelineEntry(
                id: task.id,
                date: due,
                title: task.title,
                subtitle: task.isCompleted ? "Completed" : "Due",
                kind: .task,
                context: task.context,
                freshness: .live
            )
        }
        return (events + tasks).sorted { $0.date < $1.date }
    }
}
