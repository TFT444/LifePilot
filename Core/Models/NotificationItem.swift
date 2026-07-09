import Foundation

/// A system or in-app notification surfaced to the user, distinct from a
/// `DaySignal` — notifications are things the user is told, signals are
/// things Ghost Brain reasons over. A notification is often *produced from*
/// a signal or recommendation, but the two are not interchangeable.
public struct NotificationItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let body: String
    public let receivedAt: Date
    public let sourceAgent: AgentKind?
    public let isRead: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        body: String,
        receivedAt: Date,
        sourceAgent: AgentKind? = nil,
        isRead: Bool = false
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.receivedAt = receivedAt
        self.sourceAgent = sourceAgent
        self.isRead = isRead
    }
}
