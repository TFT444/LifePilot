import Foundation
import XCTest
@testable import LifePilotGhostBrain
@testable import LifePilotCore

final class EventTextParserTests: XCTestCase {
    // A fixed, time-zone-independent clock so parsing is deterministic.
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    // Monday, 5 Jan 2026, 08:00 UTC.
    private var now: Date {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 1; comps.day = 5; comps.hour = 8
        return calendar.date(from: comps)!
    }

    private func components(_ date: Date) -> DateComponents {
        calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    }

    func testTomorrowWithTimeAndLocation() {
        let parser = EventTextParser(calendar: calendar)
        let event = parser.parse("Dentist appointment tomorrow at 2:30 PM at 220 Baker St", now: now)

        XCTAssertEqual(event.title, "Dentist appointment")
        XCTAssertEqual(event.location, "220 Baker St")
        let c = components(event.date!)
        XCTAssertEqual(c.year, 2026)
        XCTAssertEqual(c.month, 1)
        XCTAssertEqual(c.day, 6)      // tomorrow
        XCTAssertEqual(c.hour, 14)    // 2:30 PM
        XCTAssertEqual(c.minute, 30)
        XCTAssertGreaterThanOrEqual(event.confidence, 0.9)
    }

    func testTodayWith12HourTime() {
        let parser = EventTextParser(calendar: calendar)
        let event = parser.parse("Team standup today 9am", now: now)

        XCTAssertEqual(event.title, "Team standup")
        let c = components(event.date!)
        XCTAssertEqual(c.day, 5)
        XCTAssertEqual(c.hour, 9)
        XCTAssertEqual(c.minute, 0)
    }

    func testWeekdayWith24HourTime() {
        let parser = EventTextParser(calendar: calendar)
        let event = parser.parse("Flight BA208 on Friday 06:15", now: now)

        XCTAssertEqual(event.title, "Flight BA208")
        let c = components(event.date!)
        XCTAssertEqual(c.day, 9)      // Friday after Mon 5 Jan
        XCTAssertEqual(c.hour, 6)
        XCTAssertEqual(c.minute, 15)
    }

    func testExplicitDateWithoutTimeDefaultsToNineAM() {
        let parser = EventTextParser(calendar: calendar)
        let event = parser.parse("Project deadline 20 July", now: now)

        XCTAssertEqual(event.title, "Project deadline")
        let c = components(event.date!)
        XCTAssertEqual(c.month, 7)
        XCTAssertEqual(c.day, 20)
        XCTAssertEqual(c.hour, 9)
    }

    func testNoDateOrTimeYieldsNilDateAndLowConfidence() {
        let parser = EventTextParser(calendar: calendar)
        let event = parser.parse("Pay rent", now: now)

        XCTAssertEqual(event.title, "Pay rent")
        XCTAssertNil(event.date)
        XCTAssertFalse(event.isSchedulable)
        XCTAssertLessThan(event.confidence, 0.7)
    }

    func testEmptyTextIsHandled() {
        let parser = EventTextParser(calendar: calendar)
        let event = parser.parse("   ", now: now)
        XCTAssertNil(event.date)
        XCTAssertEqual(event.confidence, 0)
    }

    func testParsedEventBecomesReminder() {
        let parser = EventTextParser(calendar: calendar)
        let event = parser.parse("Meeting tomorrow at 10:00", now: now)
        let reminder = event.makeReminder()
        XCTAssertNotNil(reminder)
        XCTAssertEqual(reminder?.dueDate, event.date)
        XCTAssertEqual(reminder?.sourceAgent, .reminder)
    }
}
