import Foundation

/// A single observed fact about the user's day, before planning rules
/// turn it into a recommendation. Agents and adapters produce signals;
/// Ghost Brain / Planning fuse them.
public struct DaySignal: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let kind: Kind
    public let title: String
    public let subtitle: String?
    public let timestamp: Date
    public let sourceAgent: AgentKind
    public let freshness: DataFreshness

    public init(
        id: UUID = UUID(),
        kind: Kind,
        title: String,
        subtitle: String? = nil,
        timestamp: Date,
        sourceAgent: AgentKind,
        freshness: DataFreshness = .unknown
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.timestamp = timestamp
        self.sourceAgent = sourceAgent
        self.freshness = freshness
    }

    public enum Kind: String, Sendable, CaseIterable {
        case event
        case reminder
        case task
        case travel
        case weather
        case conflict
        case preparation
        case overload
        case freeTime
    }
}

/// How fresh the underlying observation is — surfaced on every card.
public enum DataFreshness: String, Sendable, CaseIterable, Codable {
    case live
    case cached
    case stale
    case unavailable
    case unknown
}
