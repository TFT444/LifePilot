import Foundation

/// Supplies unified timeline entries for the Timeline feature. Implementations
/// live in `Services` (store-backed / integrations) or `Mocks` (previews/tests).
public protocol TimelineProviding: Sendable {
    func loadEntries(relativeTo now: Date) async -> [TimelineEntry]
}

/// A single unified entry in the Timeline, merged across domains.
public struct TimelineEntry: Identifiable, Sendable, Hashable {
    public let id: UUID
    public let date: Date
    public let title: String
    public let subtitle: String?
    public let kind: Kind
    public let context: LifeContext
    public let freshness: DataFreshness

    public init(
        id: UUID = UUID(),
        date: Date,
        title: String,
        subtitle: String?,
        kind: Kind,
        context: LifeContext = .personal,
        freshness: DataFreshness = .live
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.subtitle = subtitle
        self.kind = kind
        self.context = context
        self.freshness = freshness
    }

    public enum Kind: String, Hashable, Sendable, CaseIterable {
        case event
        case task
        case reminder
        case recommendation
        case signal
    }
}
