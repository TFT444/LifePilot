import Foundation
import LifePilotCore

/// A single ranked, explained suggestion produced by Ghost Brain — the
/// unit that ultimately reaches the Approvals screen. Every recommendation
/// carries its own reasoning, per the Explain stage of the Core Philosophy
/// in README.md.
public struct RecommendationModel: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let reasoning: String
    public let sourceAgent: AgentKind
    public let riskLevel: RiskLevel
    public let urgency: Urgency
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        reasoning: String,
        sourceAgent: AgentKind,
        riskLevel: RiskLevel,
        urgency: Urgency,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.reasoning = reasoning
        self.sourceAgent = sourceAgent
        self.riskLevel = riskLevel
        self.urgency = urgency
        self.createdAt = createdAt
    }

    public enum Urgency: String, Comparable, CaseIterable, Sendable {
        case low
        case normal
        case high

        private var sortOrder: Int {
            switch self {
            case .low: return 0
            case .normal: return 1
            case .high: return 2
            }
        }

        public static func < (lhs: Urgency, rhs: Urgency) -> Bool {
            lhs.sortOrder < rhs.sortOrder
        }
    }
}
