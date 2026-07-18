import LifePilotCore
import XCTest
@testable import LifePilotFeatures

@MainActor
final class TimelineViewModelTests: XCTestCase {
    func testLoadPopulatesEntriesSortedByDate() async {
        let later = Date().addingTimeInterval(3600)
        let earlier = Date()
        let provider = StubTimelineProvider(entries: [
            TimelineEntry(date: later, title: "Later", subtitle: nil, kind: .event),
            TimelineEntry(date: earlier, title: "Earlier", subtitle: nil, kind: .task),
        ])
        let viewModel = TimelineViewModel(timelineProvider: provider)

        await viewModel.load()

        XCTAssertEqual(viewModel.entries.count, 2)
        XCTAssertEqual(viewModel.entries.map(\.date), [earlier, later])
    }

    func testLoadIncludesEventAndTaskKinds() async {
        let provider = StubTimelineProvider(entries: [
            TimelineEntry(date: Date(), title: "Event", subtitle: nil, kind: .event),
            TimelineEntry(date: Date(), title: "Task", subtitle: nil, kind: .task),
        ])
        let viewModel = TimelineViewModel(timelineProvider: provider)

        await viewModel.load()

        let kinds = Set(viewModel.entries.map(\.kind))
        XCTAssertTrue(kinds.contains(.event))
        XCTAssertTrue(kinds.contains(.task))
    }

    func testFilterTasksAndTravel() async {
        let provider = StubTimelineProvider(entries: [
            TimelineEntry(date: Date(), title: "Standup", subtitle: nil, kind: .event),
            TimelineEntry(date: Date(), title: "Ship deck", subtitle: nil, kind: .task),
            TimelineEntry(date: Date(), title: "Leave home", subtitle: "Travel buffer", kind: .signal),
        ])
        let viewModel = TimelineViewModel(timelineProvider: provider)
        await viewModel.load()
        XCTAssertEqual(viewModel.entries.count, 3)
        viewModel.setFilter(.tasks)
        XCTAssertEqual(viewModel.entries.count, 1)
        XCTAssertEqual(viewModel.entries.first?.kind, .task)
        viewModel.setFilter(.travel)
        XCTAssertEqual(viewModel.entries.count, 1)
        XCTAssertEqual(viewModel.entries.first?.kind, .signal)
    }
}

private struct StubTimelineProvider: TimelineProviding {
    let entries: [TimelineEntry]

    func loadEntries(relativeTo _: Date) async -> [TimelineEntry] {
        entries
    }
}
