import Foundation
import LifePilotCore
import Observation

/// Pending action proposals awaiting explicit user approval.
/// Production loads from `ApprovalStore` — no sample seeds.
@Observable
@MainActor
public final class ApprovalsViewModel {
    public private(set) var pending: [ActionProposal] = []
    public private(set) var history: [ApprovalRecord] = []
    public private(set) var lastError: String?

    private let executor: any ActionExecuting
    private let approvalStore: any ApprovalStore
    private var proposalsByID: [UUID: ActionProposal] = [:]
    private var recordsByID: [UUID: ApprovalRecord] = [:]

    public init(
        executor: any ActionExecuting,
        approvalStore: any ApprovalStore,
        seed: [ActionProposal] = []
    ) {
        self.executor = executor
        self.approvalStore = approvalStore
        for proposal in seed {
            proposalsByID[proposal.id] = proposal
            recordsByID[proposal.id] = ApprovalRecord(
                proposalID: proposal.id,
                boundFingerprint: proposal.parameterFingerprint,
                state: .pending
            )
        }
        refresh()
    }

    public func load() async {
        let stored = await approvalStore.all()
        for (proposal, record) in stored {
            proposalsByID[proposal.id] = proposal
            recordsByID[record.proposalID] = record
        }
        refresh()
    }

    public func enqueue(_ proposal: ActionProposal) async throws {
        let record = ApprovalRecord(
            proposalID: proposal.id,
            boundFingerprint: proposal.parameterFingerprint,
            state: .pending
        )
        proposalsByID[proposal.id] = proposal
        recordsByID[proposal.id] = record
        try await approvalStore.save(proposal: proposal, record: record)
        refresh()
    }

    public func refresh() {
        pending = proposalsByID.values
            .filter { recordsByID[$0.id]?.state == .pending }
            .sorted { $0.createdAt > $1.createdAt }
        history = recordsByID.values
            .sorted { ($0.decidedAt ?? .distantPast) > ($1.decidedAt ?? .distantPast) }
    }

    public func approve(_ proposal: ActionProposal) async {
        lastError = nil
        guard var record = recordsByID[proposal.id] else { return }
        record.state = .approved
        record.decidedAt = Date()
        do {
            let completed = try await executor.execute(proposal: proposal, approval: record)
            recordsByID[proposal.id] = completed
            try await approvalStore.save(proposal: proposal, record: completed)
            try await approvalStore.appendAudit(
                AuditEvent(
                    category: "approval",
                    summary: "Approved \(proposal.actionType.rawValue)",
                    proposalID: proposal.id,
                    success: true
                )
            )
        } catch {
            record.state = .failed
            record.executionResult = error.localizedDescription
            recordsByID[proposal.id] = record
            lastError = record.executionResult
            try? await approvalStore.save(proposal: proposal, record: record)
        }
        refresh()
    }

    public func reject(_ proposal: ActionProposal) async {
        guard var record = recordsByID[proposal.id] else { return }
        record.state = .rejected
        record.decidedAt = Date()
        recordsByID[proposal.id] = record
        try? await approvalStore.save(proposal: proposal, record: record)
        try? await approvalStore.appendAudit(
            AuditEvent(
                category: "approval",
                summary: "Rejected \(proposal.actionType.rawValue)",
                proposalID: proposal.id,
                success: true
            )
        )
        refresh()
    }
}
