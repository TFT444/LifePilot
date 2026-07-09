import Foundation
import LifePilotCore
import LifePilotMocks

/// Owns the Timeline screen's state: a unified, chronological stream
/// merging calendar events, emails, and tasks, per README.md's Timeline
/// feature description. Backed by `LifePilotMocks` in this phase — a real
/// implementation arrives once `Services` has live integrations
/// (docs/MASTER_ROADMAP.md Phase 7).
@Observable
@MainActor
public final class TimelineViewModel {
    public private(set) var entries: [TimelineEntry] = []

    public init() {}

    public func load() async {
        let now = Date()
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

        entries = (events + emails + tasks).sorted { $0.date < $1.date }
    }
}

/// A single unified entry in the Timeline, merged across domains. See
/// `TimelineViewModel.load()` for how domain-specific mock data is
/// projected into this shared shape.
public struct TimelineEntry: Identifiable {
    public let id: UUID
    public let date: Date
    public let title: String
    public let subtitle: String?
    public let kind: Kind

    public enum Kind: Hashable {
        case event
        case email
        case task
    }
}
