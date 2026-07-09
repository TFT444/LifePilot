/// How much scrutiny a proposed action requires before it can execute.
/// Every `ApprovedAction` in the Ghost Brain pipeline carries one of these,
/// per the Security Agent's audit role in docs/ARCHITECTURE.md.
public enum RiskLevel: String, Comparable, CaseIterable, Hashable, Sendable {
    case low
    case medium
    case high

    private var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }

    public static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
