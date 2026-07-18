import Foundation
import LifePilotCore

/// Owns the Timeline screen's state: unified chronological stream with filters.
@Observable
@MainActor
public final class TimelineViewModel {
    public enum Filter: String, CaseIterable, Sendable {
        case all
        case calendar
        case travel
        case tasks

        public var title: String {
            switch self {
            case .all: "All"
            case .calendar: "Calendar"
            case .travel: "Travel"
            case .tasks: "Tasks"
            }
        }
    }

    public private(set) var entries: [TimelineEntry] = []
    public private(set) var filter: Filter = .all
    public private(set) var isEmpty: Bool = true

    private var allEntries: [TimelineEntry] = []
    private let timelineProvider: TimelineProviding

    public init(timelineProvider: TimelineProviding) {
        self.timelineProvider = timelineProvider
    }

    public func load() async {
        allEntries = await timelineProvider.loadEntries(relativeTo: Date())
            .sorted { $0.date < $1.date }
        applyFilter()
    }

    public func setFilter(_ filter: Filter) {
        self.filter = filter
        applyFilter()
    }

    private func applyFilter() {
        switch filter {
        case .all:
            entries = allEntries
        case .calendar:
            entries = allEntries.filter { $0.kind == .event }
        case .travel:
            entries = allEntries.filter {
                $0.kind == .signal
                    || ($0.subtitle?.localizedCaseInsensitiveContains("travel") == true)
                    || ($0.subtitle?.localizedCaseInsensitiveContains("leave") == true)
                    || ($0.title.localizedCaseInsensitiveContains("leave") == true)
            }
        case .tasks:
            entries = allEntries.filter { $0.kind == .task || $0.kind == .reminder }
        }
        isEmpty = entries.isEmpty
    }
}
