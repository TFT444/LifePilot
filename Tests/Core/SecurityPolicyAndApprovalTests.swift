import Foundation
import XCTest
@testable import LifePilotCore

final class SecurityPolicyAndApprovalTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testFinanceEmailAndUnwiredExternalActionsAreNotAllowed() {
        let policy = SecurityPolicy()
        XCTAssertFalse(policy.isAllowed(.forbiddenExternalFinancial))
        XCTAssertFalse(policy.isAllowed(.forbiddenSendEmail))
        XCTAssertFalse(policy.isAllowed(.rescheduleEventKitEvent))
        XCTAssertFalse(policy.isAllowed(.createEventKitReminder))
        XCTAssertTrue(policy.isAllowed(.createLocalTask))
        XCTAssertTrue(policy.isAllowed(.scheduleNotification))
    }

    func testExecutorRejectsDeniedActionAndPersistsFailureAudit() async throws {
        let approvalStore = InMemoryApprovalStore()
        let executor = makeExecutor(approvalStore: approvalStore)
        let proposal = ActionProposal(
            actionType: .forbiddenExternalFinancial,
            title: "Pay bill",
            detail: "Must never execute",
            parameters: ["amount": "100"]
        )

        await assertDomainError(
            .unauthorizedNamed("Financial actions are outside LifePilot's scope.")
        ) {
            _ = try await executor.execute(
                proposal: proposal,
                approval: self.approved(proposal)
            )
        }

        let audit = await approvalStore.auditTrail()
        XCTAssertEqual(audit.count, 1)
        XCTAssertFalse(try XCTUnwrap(audit.first).success)
    }

    func testUnsupportedExternalActionCannotReportSuccess() async throws {
        let approvalStore = InMemoryApprovalStore()
        let executor = makeExecutor(approvalStore: approvalStore)
        let proposal = ActionProposal(
            actionType: .createEventKitReminder,
            title: "Create reminder",
            detail: "External write is not connected",
            parameters: ["title": "Call Mum"]
        )

        await assertDomainError(
            .invalidState("Apple Reminder creation is not connected yet.")
        ) {
            _ = try await executor.execute(
                proposal: proposal,
                approval: self.approved(proposal)
            )
        }

        let stored = await approvalStore.all()
        XCTAssertEqual(stored.first?.1.state, .failed)
        XCTAssertEqual(
            stored.first?.1.executionResult,
            "Apple Reminder creation is not connected yet."
        )
    }

    func testFingerprintMismatchFails() async {
        let executor = makeExecutor()
        let proposal = ActionProposal(
            actionType: .createLocalTask,
            title: "Buy milk",
            detail: "Grocery",
            parameters: ["title": "Buy milk"]
        )
        let approval = ApprovalRecord(
            proposalID: proposal.id,
            boundFingerprint: "stale-fingerprint",
            state: .approved
        )

        await assertDomainError(.conflict) {
            _ = try await executor.execute(proposal: proposal, approval: approval)
        }
    }

    func testProposalIDMismatchFails() async {
        let executor = makeExecutor()
        let proposal = ActionProposal(
            actionType: .createLocalTask,
            title: "Buy milk",
            detail: "Grocery",
            parameters: ["title": "Buy milk"]
        )
        let approval = ApprovalRecord(
            proposalID: UUID(),
            boundFingerprint: proposal.parameterFingerprint,
            state: .approved
        )

        await assertDomainError(.validationFailed(field: "proposalID")) {
            _ = try await executor.execute(proposal: proposal, approval: approval)
        }
    }

    func testExpiredProposalPersistsExpiredState() async throws {
        let approvalStore = InMemoryApprovalStore()
        let executor = makeExecutor(approvalStore: approvalStore)
        let proposal = ActionProposal(
            actionType: .createLocalTask,
            title: "Expired",
            detail: "Too late",
            parameters: ["title": "Expired"],
            expiresAt: now.addingTimeInterval(-1)
        )

        await assertDomainError(.unavailableNamed("Proposal expired.")) {
            _ = try await executor.execute(
                proposal: proposal,
                approval: self.approved(proposal)
            )
        }

        let stored = await approvalStore.all()
        XCTAssertEqual(stored.first?.1.state, .expired)
    }

    func testCreateTaskIsIdempotentAcrossExecutorRestart() async throws {
        let taskStore = FakeTaskStore()
        let approvalStore = InMemoryApprovalStore()
        let proposal = ActionProposal(
            actionType: .createLocalTask,
            title: "Walk the dog",
            detail: "Evening",
            parameters: ["title": "Walk the dog"]
        )
        let approval = approved(proposal)

        let firstExecutor = makeExecutor(
            taskStore: taskStore,
            approvalStore: approvalStore
        )
        let first = try await firstExecutor.execute(proposal: proposal, approval: approval)

        let restartedExecutor = makeExecutor(
            taskStore: taskStore,
            approvalStore: approvalStore
        )
        let second = try await restartedExecutor.execute(proposal: proposal, approval: approval)

        let tasks = await taskStore.allTasks()
        XCTAssertEqual(first.state, .completed)
        XCTAssertEqual(second.state, .completed)
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.id, proposal.id)
    }

    func testRescheduleTaskUpdatesExistingTarget() async throws {
        let taskID = UUID()
        let taskStore = FakeTaskStore(seed: [TaskItem(id: taskID, title: "Prepare deck")])
        let dueDate = now.addingTimeInterval(7200)
        let executor = makeExecutor(taskStore: taskStore)
        let proposal = ActionProposal(
            actionType: .rescheduleLocalTask,
            title: "Reschedule task",
            detail: "Move the deadline",
            parameters: [
                "taskID": taskID.uuidString,
                "dueDate": iso8601(dueDate),
            ]
        )

        _ = try await executor.execute(proposal: proposal, approval: approved(proposal))

        let tasks = await taskStore.allTasks()
        let saved = try XCTUnwrap(tasks.first)
        XCTAssertEqual(saved.dueDate, dueDate)
        XCTAssertEqual(saved.updatedAt, now)
    }

    func testMissingTaskFailsInsteadOfReportingSuccess() async {
        let executor = makeExecutor()
        let proposal = ActionProposal(
            actionType: .completeLocalTask,
            title: "Complete task",
            detail: "Missing target",
            parameters: ["taskID": UUID().uuidString]
        )

        await assertDomainError(.notFoundNamed("Task")) {
            _ = try await executor.execute(
                proposal: proposal,
                approval: self.approved(proposal)
            )
        }
    }

    func testUpdateEventRequiresAndAppliesARealChange() async throws {
        let eventID = UUID()
        let original = CalendarEvent(
            id: eventID,
            title: "Planning",
            startDate: now,
            endDate: now.addingTimeInterval(3600)
        )
        let eventStore = FakeEventStore(seed: [original])
        let executor = makeExecutor(eventStore: eventStore)
        let proposal = ActionProposal(
            actionType: .updateLocalEvent,
            title: "Update event",
            detail: "Add a room",
            parameters: [
                "eventID": eventID.uuidString,
                "title": "Planning review",
                "location": "Room 4",
            ]
        )

        _ = try await executor.execute(proposal: proposal, approval: approved(proposal))

        let events = await eventStore.allEvents()
        let saved = try XCTUnwrap(events.first)
        XCTAssertEqual(saved.title, "Planning review")
        XCTAssertEqual(saved.location, "Room 4")
    }

    func testUpdateEventRejectsEmptyMutation() async {
        let eventID = UUID()
        let event = CalendarEvent(
            id: eventID,
            title: "Planning",
            startDate: now,
            endDate: now.addingTimeInterval(3600)
        )
        let executor = makeExecutor(eventStore: FakeEventStore(seed: [event]))
        let proposal = ActionProposal(
            actionType: .updateLocalEvent,
            title: "Update event",
            detail: "No fields",
            parameters: ["eventID": eventID.uuidString]
        )

        await assertDomainError(.validationFailed(field: "parameters")) {
            _ = try await executor.execute(
                proposal: proposal,
                approval: self.approved(proposal)
            )
        }
    }

    func testDeleteLocalRecordVerifiesTargetBeforeDeleting() async throws {
        let eventID = UUID()
        let event = CalendarEvent(
            id: eventID,
            title: "Remove me",
            startDate: now,
            endDate: now.addingTimeInterval(3600)
        )
        let eventStore = FakeEventStore(seed: [event])
        let executor = makeExecutor(eventStore: eventStore)
        let proposal = ActionProposal(
            actionType: .deleteLocalRecord,
            title: "Delete event",
            detail: "Approved deletion",
            parameters: [
                "recordID": eventID.uuidString,
                "recordType": "event",
            ]
        )

        _ = try await executor.execute(proposal: proposal, approval: approved(proposal))
        let events = await eventStore.allEvents()
        XCTAssertTrue(events.isEmpty)
    }

    func testNotificationScheduleAndCancelUseInjectedAdapter() async throws {
        let scheduler = FakeNotificationScheduler(state: .authorized)
        let executor = makeExecutor(notificationScheduler: scheduler)
        let notificationID = "briefing-ready"
        let schedule = ActionProposal(
            actionType: .scheduleNotification,
            title: "Briefing ready",
            detail: "Your day is prepared.",
            parameters: [
                "notificationID": notificationID,
                "fireDate": iso8601(now.addingTimeInterval(300)),
            ]
        )
        _ = try await executor.execute(proposal: schedule, approval: approved(schedule))
        let scheduledIDs = await scheduler.scheduledIDs()
        XCTAssertEqual(scheduledIDs, Set([notificationID]))

        let cancel = ActionProposal(
            actionType: .cancelNotification,
            title: "Cancel briefing",
            detail: "No longer needed",
            parameters: ["notificationID": notificationID]
        )
        _ = try await executor.execute(proposal: cancel, approval: approved(cancel))
        let cancelledIDs = await scheduler.cancelledIDs()
        XCTAssertEqual(cancelledIDs, Set([notificationID]))
    }

    func testNotificationScheduleRequiresAuthorization() async {
        let scheduler = FakeNotificationScheduler(state: .denied)
        let executor = makeExecutor(notificationScheduler: scheduler)
        let proposal = ActionProposal(
            actionType: .scheduleNotification,
            title: "Briefing ready",
            detail: "Your day is prepared.",
            parameters: ["fireDate": iso8601(now.addingTimeInterval(300))]
        )

        await assertDomainError(
            .unauthorizedNamed("Notification permission is not authorized.")
        ) {
            _ = try await executor.execute(
                proposal: proposal,
                approval: self.approved(proposal)
            )
        }
    }

    func testSideEffectFailurePersistsFailedOutcomeAndAudit() async throws {
        let taskStore = FakeTaskStore(saveError: .unavailableNamed("Disk unavailable."))
        let approvalStore = InMemoryApprovalStore()
        let executor = makeExecutor(
            taskStore: taskStore,
            approvalStore: approvalStore
        )
        let proposal = ActionProposal(
            actionType: .createLocalTask,
            title: "Write safely",
            detail: "Persistence must succeed",
            parameters: ["title": "Write safely"]
        )

        await assertDomainError(.unavailableNamed("Disk unavailable.")) {
            _ = try await executor.execute(
                proposal: proposal,
                approval: self.approved(proposal)
            )
        }

        let stored = await approvalStore.all()
        let audit = await approvalStore.auditTrail()
        XCTAssertEqual(stored.first?.1.state, .failed)
        XCTAssertEqual(stored.first?.1.executionResult, "Disk unavailable.")
        XCTAssertFalse(try XCTUnwrap(audit.first).success)
    }

    func testAgentKindExcludesFinanceShoppingHealth() {
        let raw = Set(AgentKind.allCases.map(\.rawValue))
        XCTAssertFalse(raw.contains("finance"))
        XCTAssertFalse(raw.contains("shopping"))
        XCTAssertFalse(raw.contains("health"))
        XCTAssertFalse(raw.contains("email"))
    }

    private func makeExecutor(
        taskStore: FakeTaskStore = FakeTaskStore(),
        eventStore: FakeEventStore = FakeEventStore(),
        notificationScheduler: FakeNotificationScheduler? = nil,
        approvalStore: (any ApprovalStore)? = nil
    ) -> LocalActionExecutor {
        LocalActionExecutor(
            taskStore: taskStore,
            eventStore: eventStore,
            notificationScheduler: notificationScheduler,
            approvalStore: approvalStore,
            clock: FixedClock(now)
        )
    }

    private func approved(_ proposal: ActionProposal) -> ApprovalRecord {
        ApprovalRecord(
            proposalID: proposal.id,
            boundFingerprint: proposal.parameterFingerprint,
            state: .approved
        )
    }

    private func iso8601(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private func assertDomainError(
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
}

private actor FakeTaskStore: TaskStore {
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
        if let saveError { throw saveError }
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

private actor FakeEventStore: EventStore {
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

private actor FakeNotificationScheduler: NotificationScheduling {
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
