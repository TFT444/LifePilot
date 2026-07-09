import Foundation

/// Supplies unified timeline entries for the Timeline feature. Implementations
/// live in `Services` (live integrations) or `Mocks` (Phase 3–6 development).
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

    public init(
        id: UUID = UUID(),
        date: Date,
        title: String,
        subtitle: String?,
        kind: Kind
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.subtitle = subtitle
        self.kind = kind
    }

    public enum Kind: Hashable, Sendable {
        case event
        case email
        case task
    }
}
