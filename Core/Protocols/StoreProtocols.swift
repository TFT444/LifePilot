import Foundation

/// Stable clock for deterministic tests.
public protocol ClockProviding: Sendable {
    func now() -> Date
}

public struct SystemClock: ClockProviding {
    public init() {}

    public func now() -> Date {
        Date()
    }
}

public struct FixedClock: ClockProviding {
    private let instant: Date

    public init(_ instant: Date) {
        self.instant = instant
    }

    public func now() -> Date {
        instant
    }
}

/// Identifier factory for deterministic tests.
public protocol IdentifierProviding: Sendable {
    func next() -> UUID
}

public struct SystemIdentifierProvider: IdentifierProviding {
    public init() {}

    public func next() -> UUID {
        UUID()
    }
}

/// Offline-first task store.
public protocol TaskStore: Sendable {
    func allTasks() async -> [TaskItem]
    func save(_ task: TaskItem) async throws
    func delete(id: UUID) async throws
    func tasks(matching predicate: @Sendable (TaskItem) -> Bool) async -> [TaskItem]
}

/// Offline-first event store.
public protocol EventStore: Sendable {
    func allEvents() async -> [CalendarEvent]
    func save(_ event: CalendarEvent) async throws
    func delete(id: UUID) async throws
}

/// Preferences and memory store.
public protocol PreferenceStore: Sendable {
    func loadPreferences() async -> UserPreferences
    func savePreferences(_ preferences: UserPreferences) async throws
    func allMemory() async -> [MemoryItem]
    func saveMemory(_ item: MemoryItem) async throws
    func deleteMemory(id: UUID) async throws
    func exportAll() async throws -> Data
    func deleteAllLifePilotData() async throws
}

/// Deterministic planning engine.
public protocol PlanningEngine: Sendable {
    func analyze(
        events: [CalendarEvent],
        tasks: [TaskItem],
        preferences: UserPreferences,
        now: Date
    ) -> [PlanningFinding]
}

/// Approval-gated execution boundary.
public protocol ActionExecuting: Sendable {
    func isAllowed(_ actionType: ActionProposal.ActionType) -> Bool
    func execute(proposal: ActionProposal, approval: ApprovalRecord) async throws -> ApprovalRecord
}

/// Local notification scheduling (fakes in tests; UserNotifications in app).
public protocol NotificationScheduling: Sendable {
    func schedule(id: String, title: String, body: String, fireDate: Date) async throws
    func cancel(id: String) async throws
}
