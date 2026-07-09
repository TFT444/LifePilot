import Foundation
import LifePilotCore

/// Mock timeline data for Phase 3–6, until live `Services` integrations land.
public struct MockTimelineProvider: TimelineProviding {
    public init() {}

    public func loadEntries(relativeTo now: Date) async -> [TimelineEntry] {
        let events = MockCalendar.events(relativeTo: now).map {
            TimelineEntry(
                id: $0.id,
                date: $0.startDate,
                title: $0.title,
                subtitle: $0.location,
                kind: .event
            )
        }
        let emails = MockEmail.messages(relativeTo: now).map {
            TimelineEntry(
                id: $0.id,
                date: $0.receivedAt,
                title: $0.subject,
                subtitle: $0.sender,
                kind: .email
            )
        }
        let tasks = MockTasks.items(relativeTo: now).compactMap { task -> TimelineEntry? in
            guard let dueDate = task.dueDate else { return nil }
            return TimelineEntry(
                id: task.id,
                date: dueDate,
                title: task.title,
                subtitle: "Due",
                kind: .task
            )
        }

        return (events + emails + tasks).sorted { $0.date < $1.date }
    }
}
