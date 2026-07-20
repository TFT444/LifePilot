import Foundation
import XCTest
@testable import LifePilotCore
@testable import LifePilotGhostBrain

final class EventTextParserTests: XCTestCase {
    /// A fixed, time-zone-independent clock so parsing is deterministic.
    private func utcCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        if let utc = TimeZone(identifier: "UTC") {
            cal.timeZone = utc
        }
        return cal
    }

    /// Monday, 5 Jan 2026, 08:00 UTC.
    private func referenceNow() -> Date {
        makeDate(year: 2026, month: 1, day: 5, hour: 8)
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        return utcCalendar().date(from: comps) ?? Date(timeIntervalSince1970: 0)
    }

    private func parts(_ date: Date) -> DateComponents {
        utcCalendar().dateComponents([.year, .month, .day, .hour, .minute], from: date)
    }

    func testTomorrowWithTimeAndLocation() throws {
        let parser = EventTextParser(calendar: utcCalendar())
        let event = parser.parse("Dentist appointment tomorrow at 2:30 PM at 220 Baker St", now: referenceNow())

        XCTAssertEqual(event.title, "Dentist appointment")
        XCTAssertEqual(event.location, "220 Baker St")
        let date = try XCTUnwrap(event.date)
        let comps = parts(date)
        XCTAssertEqual(comps.year, 2026)
        XCTAssertEqual(comps.month, 1)
        XCTAssertEqual(comps.day, 6) // tomorrow
        XCTAssertEqual(comps.hour, 14) // 2:30 PM
        XCTAssertEqual(comps.minute, 30)
        XCTAssertGreaterThanOrEqual(event.confidence, 0.9)
    }

    func testTodayWith12HourTime() throws {
        let parser = EventTextParser(calendar: utcCalendar())
        let event = parser.parse("Team standup today 9am", now: referenceNow())

        XCTAssertEqual(event.title, "Team standup")
        let comps = try parts(XCTUnwrap(event.date))
        XCTAssertEqual(comps.day, 5)
        XCTAssertEqual(comps.hour, 9)
        XCTAssertEqual(comps.minute, 0)
    }

    func testWeekdayWith24HourTime() throws {
        let parser = EventTextParser(calendar: utcCalendar())
        let event = parser.parse("Flight BA208 on Friday 06:15", now: referenceNow())

        XCTAssertEqual(event.title, "Flight BA208")
        let comps = try parts(XCTUnwrap(event.date))
        XCTAssertEqual(comps.day, 9) // Friday after Mon 5 Jan
        XCTAssertEqual(comps.hour, 6)
        XCTAssertEqual(comps.minute, 15)
    }

    func testExplicitDateWithoutTimeDefaultsToNineAM() throws {
        let parser = EventTextParser(calendar: utcCalendar())
        let event = parser.parse("Project deadline 20 July", now: referenceNow())

        XCTAssertEqual(event.title, "Project deadline")
        let comps = try parts(XCTUnwrap(event.date))
        XCTAssertEqual(comps.month, 7)
        XCTAssertEqual(comps.day, 20)
        XCTAssertEqual(comps.hour, 9)
    }

    func testNoDateOrTimeYieldsNilDateAndLowConfidence() {
        let parser = EventTextParser(calendar: utcCalendar())
        let event = parser.parse("Pay rent", now: referenceNow())

        XCTAssertEqual(event.title, "Pay rent")
        XCTAssertNil(event.date)
        XCTAssertFalse(event.isSchedulable)
        XCTAssertLessThan(event.confidence, 0.7)
    }

    func testEmptyTextIsHandled() {
        let parser = EventTextParser(calendar: utcCalendar())
        let event = parser.parse("   ", now: referenceNow())
        XCTAssertNil(event.date)
        XCTAssertEqual(event.confidence, 0)
    }

    func testParsedEventBecomesReminder() throws {
        let parser = EventTextParser(calendar: utcCalendar())
        let event = parser.parse("Meeting tomorrow at 10:00", now: referenceNow())
        let reminder = try XCTUnwrap(event.makeReminder())
        XCTAssertEqual(reminder.dueDate, event.date)
        XCTAssertEqual(reminder.sourceAgent, .reminder)
    }
}
