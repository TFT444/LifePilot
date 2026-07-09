import Foundation

/// A single calendar event, as read from the user's calendar. This is the
/// Domain-layer shape agents and Ghost Brain reason over — see
/// docs/ARCHITECTURE.md's Dependency Rules on Integrations being adapters,
/// not sources of truth for meaning.
public struct CalendarEvent: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let location: String?
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let attendeeCount: Int

    public init(
        id: UUID = UUID(),
        title: String,
        location: String? = nil,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        attendeeCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.attendeeCount = attendeeCount
    }

    /// Whether this event's time window overlaps another's — the basic
    /// building block for Calendar Agent conflict detection.
    public func overlaps(_ other: CalendarEvent) -> Bool {
        startDate < other.endDate && other.startDate < endDate
    }
}
