import Foundation

public enum ActionExecutionDisposition: Sendable, Equatable {
    case allowed
    case unsupported(String)
    case denied(String)
}

/// Allow/deny policy for executable action types. Financial and auto-email
/// actions are permanently denied. External writes stay unsupported until a
/// concrete, authorization-aware executor is injected.
public struct SecurityPolicy: Sendable {
    public init() {}

    public func disposition(
        for actionType: ActionProposal.ActionType
    ) -> ActionExecutionDisposition {
        switch actionType {
        case .forbiddenExternalFinancial:
            return .denied("Financial actions are outside LifePilot's scope.")
        case .forbiddenSendEmail:
            return .denied("LifePilot does not send messages automatically.")
        case .rescheduleEventKitEvent:
            return .unsupported("Calendar event writes are not connected yet.")
        case .createEventKitReminder:
            return .unsupported("Apple Reminder creation is not connected yet.")
        case .createLocalTask, .completeLocalTask, .rescheduleLocalTask,
             .createLocalEvent, .updateLocalEvent, .deleteLocalRecord,
             .scheduleNotification, .cancelNotification:
            return .allowed
        }
    }

    public func isAllowed(_ actionType: ActionProposal.ActionType) -> Bool {
        if case .allowed = disposition(for: actionType) {
            return true
        }
        return false
    }
}

/// Executes approved proposals against local stores and injected system
/// adapters. Every action type is handled explicitly; unsupported actions fail
/// before any success state or audit entry can be produced.
public actor LocalActionExecutor: ActionExecuting {
    private let policy: SecurityPolicy
    private let taskStore: any TaskStore
    private let eventStore: any EventStore
    private let notificationScheduler: (any NotificationScheduling)?
    private let approvalStore: (any ApprovalStore)?
    private let clock: any ClockProviding
    private var executedProposalIDs: Set<UUID> = []
    private var auditLog: [AuditEvent] = []

    public init(
        policy: SecurityPolicy = SecurityPolicy(),
        taskStore: any TaskStore,
        eventStore: any EventStore,
        notificationScheduler: (any NotificationScheduling)? = nil,
        approvalStore: (any ApprovalStore)? = nil,
        clock: any ClockProviding = SystemClock()
    ) {
        self.policy = policy
        self.taskStore = taskStore
        self.eventStore = eventStore
        self.notificationScheduler = notificationScheduler
        self.approvalStore = approvalStore
        self.clock = clock
    }

    public nonisolated func isAllowed(_ actionType: ActionProposal.ActionType) -> Bool {
        policy.isAllowed(actionType)
    }

    public func execute(
        proposal: ActionProposal,
        approval: ApprovalRecord
    ) async throws -> ApprovalRecord {
        do {
            try validateBindingAndPolicy(proposal: proposal, approval: approval)
        } catch {
            await persistFailure(proposal: proposal, approval: approval, error: error)
            throw error
        }

        if let completed = await persistedCompletion(for: proposal) {
            return completed
        }

        do {
            try validateExecutionState(proposal: proposal, approval: approval)
        } catch {
            await persistFailure(proposal: proposal, approval: approval, error: error)
            throw error
        }

        if executedProposalIDs.contains(proposal.id) {
            var result = approval
            result.state = .completed
            result.executionResult = "Already executed"
            result.decidedAt = clock.now()
            try await persistSuccess(proposal: proposal, result: result, wasRetry: true)
            return result
        }

        do {
            try await applySideEffects(for: proposal)
            executedProposalIDs.insert(proposal.id)

            var result = approval
            result.state = .completed
            result.executionResult = "Executed"
            result.decidedAt = clock.now()
            try await persistSuccess(proposal: proposal, result: result, wasRetry: false)
            return result
        } catch {
            await persistFailure(proposal: proposal, approval: approval, error: error)
            throw error
        }
    }

    public func auditEvents() -> [AuditEvent] {
        auditLog
    }

    private func validateBindingAndPolicy(
        proposal: ActionProposal,
        approval: ApprovalRecord
    ) throws {
        guard approval.proposalID == proposal.id else {
            throw DomainError.validationFailed(field: "proposalID")
        }
        guard approval.boundFingerprint == proposal.parameterFingerprint else {
            throw DomainError.conflict
        }

        switch policy.disposition(for: proposal.actionType) {
        case .allowed:
            break
        case let .unsupported(reason):
            throw DomainError.invalidState(reason)
        case let .denied(reason):
            throw DomainError.unauthorizedNamed(reason)
        }
    }

    private func validateExecutionState(
        proposal: ActionProposal,
        approval: ApprovalRecord
    ) throws {
        guard approval.state == .approved else {
            throw DomainError.invalidState("Approval is not in the approved state.")
        }
        if let expiresAt = proposal.expiresAt, expiresAt < clock.now() {
            throw DomainError.unavailableNamed("Proposal expired.")
        }
    }

    private func persistedCompletion(for proposal: ActionProposal) async -> ApprovalRecord? {
        guard let approvalStore else { return nil }
        let stored = await approvalStore.all()
        return stored.first { storedProposal, record in
            storedProposal.id == proposal.id
                && storedProposal.parameterFingerprint == proposal.parameterFingerprint
                && record.state == .completed
        }?.1
    }

    private func applySideEffects(for proposal: ActionProposal) async throws {
        switch proposal.actionType {
        case .createLocalTask:
            try await createLocalTask(from: proposal)
        case .completeLocalTask:
            try await completeTask(from: proposal)
        case .rescheduleLocalTask:
            try await rescheduleTask(from: proposal)
        case .createLocalEvent:
            try await createLocalEvent(from: proposal)
        case .updateLocalEvent:
            try await updateLocalEvent(from: proposal)
        case .deleteLocalRecord:
            try await deleteLocalRecord(from: proposal)
        case .scheduleNotification:
            try await scheduleNotification(from: proposal)
        case .cancelNotification:
            try await cancelNotification(from: proposal)
        case .rescheduleEventKitEvent:
            throw DomainError.invalidState("Calendar event writes are not connected yet.")
        case .createEventKitReminder:
            throw DomainError.invalidState("Apple Reminder creation is not connected yet.")
        case .forbiddenExternalFinancial, .forbiddenSendEmail:
            throw DomainError.unauthorized
        }
    }

    private func createLocalTask(from proposal: ActionProposal) async throws {
        let title = try requiredString("title", in: proposal, fallback: proposal.title)
        let dueDate = try optionalDate("dueDate", in: proposal)
        try await taskStore.save(
            TaskItem(
                id: proposal.id,
                title: title,
                notes: proposal.parameters["notes"],
                dueDate: dueDate,
                createdAt: proposal.createdAt,
                updatedAt: clock.now()
            )
        )
    }

    private func completeTask(from proposal: ActionProposal) async throws {
        var task = try await existingTask(from: proposal)
        task.isCompleted = true
        task.completedAt = clock.now()
        task.updatedAt = clock.now()
        try await taskStore.save(task)
    }

    private func rescheduleTask(from proposal: ActionProposal) async throws {
        var task = try await existingTask(from: proposal)
        task.dueDate = try requiredDate("dueDate", in: proposal)
        task.updatedAt = clock.now()
        try await taskStore.save(task)
    }

    private func existingTask(from proposal: ActionProposal) async throws -> TaskItem {
        let id = try requiredUUID("taskID", in: proposal)
        let tasks = await taskStore.allTasks()
        guard let task = tasks.first(where: { $0.id == id }) else {
            throw DomainError.notFoundNamed("Task")
        }
        return task
    }

    private func createLocalEvent(from proposal: ActionProposal) async throws {
        let title = try requiredString("title", in: proposal, fallback: proposal.title)
        let start = try optionalDate("startDate", in: proposal) ?? clock.now()
        let end = try optionalDate("endDate", in: proposal)
            ?? start.addingTimeInterval(3600)
        guard end > start else {
            throw DomainError.validationFailed(field: "endDate")
        }
        try await eventStore.save(
            CalendarEvent(
                id: proposal.id,
                title: title,
                notes: proposal.parameters["notes"],
                location: proposal.parameters["location"],
                startDate: start,
                endDate: end
            )
        )
    }

    private func updateLocalEvent(from proposal: ActionProposal) async throws {
        let id = try requiredUUID("eventID", in: proposal)
        let events = await eventStore.allEvents()
        guard var event = events.first(where: { $0.id == id }) else {
            throw DomainError.notFoundNamed("Event")
        }

        var changed = false
        if let title = proposal.parameters["title"] {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DomainError.validationFailed(field: "title")
            }
            event.title = title
            changed = true
        }
        if let notes = proposal.parameters["notes"] {
            event.notes = notes.isEmpty ? nil : notes
            changed = true
        }
        if let location = proposal.parameters["location"] {
            event.location = location.isEmpty ? nil : location
            changed = true
        }
        if proposal.parameters["startDate"] != nil {
            event.startDate = try requiredDate("startDate", in: proposal)
            changed = true
        }
        if proposal.parameters["endDate"] != nil {
            event.endDate = try requiredDate("endDate", in: proposal)
            changed = true
        }
        if let isAllDay = proposal.parameters["isAllDay"] {
            guard let parsed = Bool(isAllDay) else {
                throw DomainError.validationFailed(field: "isAllDay")
            }
            event.isAllDay = parsed
            changed = true
        }
        guard changed else {
            throw DomainError.validationFailed(field: "parameters")
        }
        guard event.endDate > event.startDate else {
            throw DomainError.validationFailed(field: "endDate")
        }
        try await eventStore.save(event)
    }

    private func deleteLocalRecord(from proposal: ActionProposal) async throws {
        let id = try requiredUUID("recordID", in: proposal)
        let recordType = try requiredString("recordType", in: proposal).lowercased()
        switch recordType {
        case "task":
            guard (await taskStore.allTasks()).contains(where: { $0.id == id }) else {
                throw DomainError.notFoundNamed("Task")
            }
            try await taskStore.delete(id: id)
        case "event":
            guard (await eventStore.allEvents()).contains(where: { $0.id == id }) else {
                throw DomainError.notFoundNamed("Event")
            }
            try await eventStore.delete(id: id)
        default:
            throw DomainError.validationFailed(field: "recordType")
        }
    }

    private func scheduleNotification(from proposal: ActionProposal) async throws {
        guard let notificationScheduler else {
            throw DomainError.invalidState("Notification scheduling is not configured.")
        }
        guard await notificationScheduler.authorizationState() == .authorized else {
            throw DomainError.unauthorizedNamed("Notification permission is not authorized.")
        }
        let id = proposal.parameters["notificationID"] ?? proposal.id.uuidString
        let title = try requiredString("title", in: proposal, fallback: proposal.title)
        let body = proposal.parameters["body"] ?? proposal.detail
        let fireDate = try requiredDate("fireDate", in: proposal)
        try await notificationScheduler.schedule(
            id: id,
            title: title,
            body: body,
            fireDate: fireDate
        )
    }

    private func cancelNotification(from proposal: ActionProposal) async throws {
        guard let notificationScheduler else {
            throw DomainError.invalidState("Notification scheduling is not configured.")
        }
        let id = try requiredString("notificationID", in: proposal)
        try await notificationScheduler.cancel(id: id)
    }

    private func requiredUUID(_ key: String, in proposal: ActionProposal) throws -> UUID {
        let value = try requiredString(key, in: proposal)
        guard let id = UUID(uuidString: value) else {
            throw DomainError.validationFailed(field: key)
        }
        return id
    }

    private func requiredString(
        _ key: String,
        in proposal: ActionProposal,
        fallback: String? = nil
    ) throws -> String {
        let value = proposal.parameters[key] ?? fallback ?? ""
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw DomainError.validationFailed(field: key)
        }
        return trimmed
    }

    private func requiredDate(_ key: String, in proposal: ActionProposal) throws -> Date {
        guard let date = try optionalDate(key, in: proposal) else {
            throw DomainError.validationFailed(field: key)
        }
        return date
    }

    private func optionalDate(_ key: String, in proposal: ActionProposal) throws -> Date? {
        guard let value = proposal.parameters[key] else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: value) {
            return date
        }
        throw DomainError.validationFailed(field: key)
    }

    private func persistSuccess(
        proposal: ActionProposal,
        result: ApprovalRecord,
        wasRetry: Bool
    ) async throws {
        let event = AuditEvent(
            timestamp: clock.now(),
            category: "execution",
            summary: wasRetry
                ? "Skipped duplicate \(proposal.actionType.rawValue)"
                : "Executed \(proposal.actionType.rawValue)",
            proposalID: proposal.id,
            success: true
        )
        auditLog.append(event)
        if let approvalStore {
            try await approvalStore.save(proposal: proposal, record: result)
            try await approvalStore.appendAudit(event)
        }
    }

    private func persistFailure(
        proposal: ActionProposal,
        approval: ApprovalRecord,
        error: Error
    ) async {
        var failed = approval
        failed.state = isExpiry(error) ? .expired : .failed
        failed.executionResult = error.localizedDescription
        failed.decidedAt = clock.now()
        let event = AuditEvent(
            timestamp: clock.now(),
            category: "execution",
            summary: "Failed \(proposal.actionType.rawValue): \(error.localizedDescription)",
            proposalID: proposal.id,
            success: false
        )
        auditLog.append(event)
        if let approvalStore {
            try? await approvalStore.save(proposal: proposal, record: failed)
            try? await approvalStore.appendAudit(event)
        }
    }

    private func isExpiry(_ error: Error) -> Bool {
        guard let domainError = error as? DomainError else { return false }
        return domainError == .unavailableNamed("Proposal expired.")
    }
}
