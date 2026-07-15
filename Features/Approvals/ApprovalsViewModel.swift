import Foundation
import LifePilotCore
import Observation

/// Pending action proposals awaiting explicit user approval.
@Observable
@MainActor
public final class ApprovalsViewModel {
    public private(set) var pending: [ActionProposal] = []
    public private(set) var history: [ApprovalRecord] = []
    public private(set) var lastError: String?

    private let executor: any ActionExecuting
    private var proposalsByID: [UUID: ActionProposal] = [:]
    private var recordsByID: [UUID: ApprovalRecord] = [:]

    public init(executor: any ActionExecuting, seed: [ActionProposal] = []) {
        self.executor = executor
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
        } catch {
            record.state = .failed
            record.executionResult = String(describing: error)
            recordsByID[proposal.id] = record
            lastError = record.executionResult
        }
        refresh()
    }

    public func reject(_ proposal: ActionProposal) {
        guard var record = recordsByID[proposal.id] else { return }
        record.state = .rejected
        record.decidedAt = Date()
        recordsByID[proposal.id] = record
        refresh()
    }

    public static func sampleProposals(now: Date = Date()) -> [ActionProposal] {
        [
            ActionProposal(
                actionType: .createLocalTask,
                title: "Block focus time for board deck",
                detail: "Create a 45-minute local task for this afternoon.",
                parameters: ["title": "Board deck focus block"],
                evidence: [
                    EvidenceItem(
                        summary: "High-priority task due today with limited free time",
                        sourceAgent: .planning,
                        observedAt: now
                    ),
                ],
                riskLevel: .low,
                createdAt: now
            ),
        ]
    }
}
