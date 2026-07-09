import Foundation
import XCTest
@testable import LifePilotCore

final class CalendarEventTests: XCTestCase {
    func testOverlappingEventsReturnTrue() {
        let now = Date()
        let first = CalendarEvent(
            title: "First",
            startDate: now,
            endDate: now.addingTimeInterval(3600)
        )
        let second = CalendarEvent(
            title: "Second",
            startDate: now.addingTimeInterval(1800),
            endDate: now.addingTimeInterval(5400)
        )

        XCTAssertTrue(first.overlaps(second))
        XCTAssertTrue(second.overlaps(first))
    }

    func testNonOverlappingEventsReturnFalse() {
        let now = Date()
        let first = CalendarEvent(
            title: "First",
            startDate: now,
            endDate: now.addingTimeInterval(3600)
        )
        let second = CalendarEvent(
            title: "Second",
            startDate: now.addingTimeInterval(3600),
            endDate: now.addingTimeInterval(7200)
        )

        XCTAssertFalse(first.overlaps(second))
    }
}
