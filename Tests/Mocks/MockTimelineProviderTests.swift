import XCTest
@testable import LifePilotMocks

final class MockTimelineProviderTests: XCTestCase {
    func testLoadEntriesReturnsSortedResults() async {
        let provider = MockTimelineProvider()
        let entries = await provider.loadEntries(relativeTo: Date())

        XCTAssertFalse(entries.isEmpty)
        XCTAssertEqual(entries, entries.sorted { $0.date < $1.date })
    }
}
