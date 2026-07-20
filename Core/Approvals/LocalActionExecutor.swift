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
    let policy: SecurityPolicy
    let taskStore: any TaskStore
    let eventStore: any EventStore
    let notificationScheduler: (any NotificationScheduling)?
    private let approvalStore: (any ApprovalStore)?
    let clock: any ClockProviding
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
