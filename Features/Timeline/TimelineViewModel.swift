import Foundation
import LifePilotCore

/// Owns the Timeline screen's state: a unified, chronological stream
/// merging calendar events, emails, and tasks, per README.md's Timeline
/// feature description. Backed by `TimelineProviding` — live integrations
/// arrive in Phase 7 via `Services`.
@Observable
@MainActor
public final class TimelineViewModel {
    public private(set) var entries: [TimelineEntry] = []

    private let timelineProvider: TimelineProviding

    public init(timelineProvider: TimelineProviding) {
        self.timelineProvider = timelineProvider
    }

    public func load() async {
        entries = await timelineProvider.loadEntries(relativeTo: Date())
            .sorted { $0.date < $1.date }
    }
}
