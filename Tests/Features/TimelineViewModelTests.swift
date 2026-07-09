import XCTest
@testable import LifePilotFeatures

@MainActor
final class TimelineViewModelTests: XCTestCase {
    func testLoadPopulatesEntriesSortedByDate() async {
        let viewModel = TimelineViewModel()

        await viewModel.load()

        XCTAssertFalse(viewModel.entries.isEmpty)

        let dates = viewModel.entries.map(\.date)
        XCTAssertEqual(dates, dates.sorted())
    }

    func testLoadIncludesAllEntryKinds() async {
        let viewModel = TimelineViewModel()

        await viewModel.load()

        let kinds = Set(viewModel.entries.map(\.kind))
        XCTAssertTrue(kinds.contains(.event))
        XCTAssertTrue(kinds.contains(.email))
    }
}
