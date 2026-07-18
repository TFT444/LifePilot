import LifePilotCore
import XCTest
@testable import LifePilotFeatures
@testable import LifePilotServices

@MainActor
final class SearchViewModelTests: XCTestCase {
    func testSearchMatchesTasksAndEvents() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let viewModel = SearchViewModel(
            taskStore: InMemoryTaskStore(seed: [
                TaskItem(title: "Pack for Paris", dueDate: now),
                TaskItem(title: "Buy milk"),
            ]),
            eventStore: InMemoryEventStore(seed: [
                CalendarEvent(
                    title: "Paris flight",
                    startDate: now.addingTimeInterval(3600),
                    endDate: now.addingTimeInterval(7200)
                ),
            ])
        )
        viewModel.query = "paris"
        await viewModel.search()
        XCTAssertEqual(viewModel.results.count, 2)
        XCTAssertTrue(viewModel.results.contains { $0.title.contains("Paris") })
    }

    func testEmptyQueryClearsResults() async {
        let viewModel = SearchViewModel(
            taskStore: InMemoryTaskStore(seed: [TaskItem(title: "Hello")]),
            eventStore: InMemoryEventStore()
        )
        viewModel.query = "hello"
        await viewModel.search()
        XCTAssertFalse(viewModel.results.isEmpty)
        viewModel.query = "  "
        await viewModel.search()
        XCTAssertTrue(viewModel.results.isEmpty)
    }
}
