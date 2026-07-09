import Foundation

/// A single observed fact about the user's day, before any reasoning has
/// been applied to it. Signals are what agents produce from `observe()`,
/// per the `Agent` protocol contract in docs/ARCHITECTURE.md.
public struct DaySignal: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let kind: Kind
    public let title: String
    public let subtitle: String?
    public let timestamp: Date
    public let sourceAgent: AgentKind

    public init(
        id: UUID = UUID(),
        kind: Kind,
        title: String,
        subtitle: String? = nil,
        timestamp: Date,
        sourceAgent: AgentKind
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.timestamp = timestamp
        self.sourceAgent = sourceAgent
    }

    public enum Kind: String, Sendable {
        case event
        case message
        case reminder
        case travel
        case finance
        case health
        case weather
    }
}
