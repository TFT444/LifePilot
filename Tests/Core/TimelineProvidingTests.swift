import XCTest
@testable import LifePilotCore

final class TimelineProvidingTests: XCTestCase {
    func testTimelineEntryKindsAreDistinct() {
        let event = TimelineEntry(date: Date(), title: "A", subtitle: nil, kind: .event)
        let email = TimelineEntry(date: Date(), title: "B", subtitle: nil, kind: .email)
        XCTAssertNotEqual(event.kind, email.kind)
    }
}
