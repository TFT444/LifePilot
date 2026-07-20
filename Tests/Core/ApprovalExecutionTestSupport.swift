import Foundation
import XCTest
@testable import LifePilotCore

func makeExecutor(
    taskStore: FakeTaskStore = FakeTaskStore(),
    eventStore: FakeEventStore = FakeEventStore(),
    notificationScheduler: FakeNotificationScheduler? = nil,
    remindersIntegration: (any RemindersIntegrating)? = nil,
    approvalStore: (any ApprovalStore)? = nil
) -> LocalActionExecutor {
    LocalActionExecutor(
        policy: SecurityPolicy(allowReminderWrites: remindersIntegration != nil),
        taskStore: taskStore,
        eventStore: eventStore,
        notificationScheduler: notificationScheduler,
        remindersIntegration: remindersIntegration,
        approvalStore: approvalStore,
        clock: FixedClock(Date(timeIntervalSince1970: 1_700_000_000))
    )
}

actor FakeRemindersIntegration: RemindersIntegrating {
    struct Creation: Sendable {
        let title: String
        let notes: String?
        let dueDate: Date?
        let recurrence: RecurrenceRule?
    }

    private var state: CapabilityState
    private(set) var creations: [Creation] = []

    init(state: CapabilityState = .authorized) {
        self.state = state
    }

    func authorizationState() async -> CapabilityState {
        state
    }

    func requestAccess() async throws -> Bool {
        state == .authorized || state == .limited
    }

    func fetchOpenReminders() async throws -> [TaskItem] {
        []
    }

    func createReminder(
        title: String,
        notes: String?,
        dueDate: Date?,
        recurrence: RecurrenceRule?
    ) async throws -> String {
        guard state == .authorized || state == .limited else {
            throw DomainError.unavailableNamed("Reminders access denied")
        }
        creations.append(Creation(
            title: title,
            notes: notes,
            dueDate: dueDate,
            recurrence: recurrence
        ))
        return "external-reminder-id"
    }

    func creationCount() -> Int {
        creations.count
    }

    func lastCreation() -> Creation? {
        creations.last
    }

    func setState(_ state: CapabilityState) {
        self.state = state
    }
}

func approved(_ proposal: ActionProposal) -> ApprovalRecord {
    ApprovalRecord(
        proposalID: proposal.id,
        boundFingerprint: proposal.parameterFingerprint,
        state: .approved
    )
}

func iso8601(_ date: Date) -> String {
    ISO8601DateFormatter().string(from: date)
}

func assertDomainError(
    _ expected: DomainError,
    operation: () async throws -> Void
) async {
    do {
        try await operation()
        XCTFail("Expected \(expected)")
    } catch let error as DomainError {
        XCTAssertEqual(error, expected)
    } catch {
        XCTFail("Unexpected error \(error)")
    }
}

actor FakeTaskStore: TaskStore {
    private var items: [UUID: TaskItem]
    private let saveError: DomainError?

    init(seed: [TaskItem] = [], saveError: DomainError? = nil) {
        items = Dictionary(uniqueKeysWithValues: seed.map { ($0.id, $0) })
        self.saveError = saveError
    }

    func allTasks() async -> [TaskItem] {
        Array(items.values)
    }

    func save(_ task: TaskItem) async throws {
        if let saveError {
            throw saveError
        }
        items[task.id] = task
    }

    func delete(id: UUID) async throws {
        guard items.removeValue(forKey: id) != nil else {
            throw DomainError.notFound
        }
    }

    func tasks(matching predicate: @Sendable (TaskItem) -> Bool) async -> [TaskItem] {
        items.values.filter(predicate)
    }
}

actor FakeEventStore: EventStore {
    private var items: [UUID: CalendarEvent]

    init(seed: [CalendarEvent] = []) {
        items = Dictionary(uniqueKeysWithValues: seed.map { ($0.id, $0) })
    }

    func allEvents() async -> [CalendarEvent] {
        Array(items.values)
    }

    func save(_ event: CalendarEvent) async throws {
        items[event.id] = event
    }

    func delete(id: UUID) async throws {
        guard items.removeValue(forKey: id) != nil else {
            throw DomainError.notFound
        }
    }
}

actor FakeNotificationScheduler: NotificationScheduling {
    private let state: PermissionState
    private var scheduled: Set<String> = []
    private var cancelled: Set<String> = []

    init(state: PermissionState) {
        self.state = state
    }

    func authorizationState() async -> PermissionState {
        state
    }

    func requestAuthorization() async throws -> Bool {
        state == .authorized
    }

    func schedule(
        id: String,
        title _: String,
        body _: String,
        fireDate _: Date
    ) async throws {
        scheduled.insert(id)
    }

    func cancel(id: String) async throws {
        cancelled.insert(id)
    }

    func cancelAll() async throws {
        cancelled.formUnion(scheduled)
    }

    func scheduledIDs() -> Set<String> {
        scheduled
    }

    func cancelledIDs() -> Set<String> {
        cancelled
    }
}
