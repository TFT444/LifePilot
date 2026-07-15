import Foundation

/// Exact parameters for an external or local side-effecting action.
/// Approval binds to this payload; any edit requires a new confirmation.
public struct ActionProposal: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var actionType: ActionType
    public var title: String
    public var detail: String
    public var parameters: [String: String]
    public var evidence: [EvidenceItem]
    public var riskLevel: RiskLevel
    public var createdAt: Date
    public var expiresAt: Date?
    public var parameterFingerprint: String

    public init(
        id: UUID = UUID(),
        actionType: ActionType,
        title: String,
        detail: String,
        parameters: [String: String],
        evidence: [EvidenceItem] = [],
        riskLevel: RiskLevel = .low,
        createdAt: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.actionType = actionType
        self.title = title
        self.detail = detail
        self.parameters = parameters
        self.evidence = evidence
        self.riskLevel = riskLevel
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        parameterFingerprint = ActionProposal.fingerprint(parameters)
    }

    public static func fingerprint(_ parameters: [String: String]) -> String {
        parameters.keys.sorted().map { key in
            "\(key)=\(parameters[key] ?? "")"
        }.joined(separator: "|")
    }

    public enum ActionType: String, CaseIterable, Sendable, Codable {
        case createLocalTask
        case completeLocalTask
        case rescheduleLocalTask
        case createLocalEvent
        case updateLocalEvent
        case deleteLocalRecord
        case scheduleNotification
        case cancelNotification
        case rescheduleEventKitEvent
        case createEventKitReminder
        /// Explicitly denied by security policy — never executable.
        case forbiddenExternalFinancial
        case forbiddenSendEmail
    }
}

public enum ApprovalState: String, CaseIterable, Sendable, Codable {
    case pending
    case approved
    case rejected
    case expired
    case failed
    case undone
    case completed
}

public struct ApprovalRecord: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var proposalID: UUID
    public var boundFingerprint: String
    public var state: ApprovalState
    public var decidedAt: Date?
    public var executionResult: String?
    public var undoAvailable: Bool

    public init(
        id: UUID = UUID(),
        proposalID: UUID,
        boundFingerprint: String,
        state: ApprovalState = .pending,
        decidedAt: Date? = nil,
        executionResult: String? = nil,
        undoAvailable: Bool = false
    ) {
        self.id = id
        self.proposalID = proposalID
        self.boundFingerprint = boundFingerprint
        self.state = state
        self.decidedAt = decidedAt
        self.executionResult = executionResult
        self.undoAvailable = undoAvailable
    }
}

/// Append-only audit entry. Never store secrets or raw private payloads.
public struct AuditEvent: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var timestamp: Date
    public var category: String
    public var summary: String
    public var proposalID: UUID?
    public var success: Bool

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        category: String,
        summary: String,
        proposalID: UUID? = nil,
        success: Bool
    ) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.summary = summary
        self.proposalID = proposalID
        self.success = success
    }
}
