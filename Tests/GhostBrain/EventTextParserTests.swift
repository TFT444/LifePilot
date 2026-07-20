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
        XCTAssertTrue(event.ambiguities.contains(.missingTime))
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

    func testRecurringInputCapturesIntervalWithoutInventingMissingDate() throws {
        let parser = EventTextParser(calendar: utcCalendar())
        let event = parser.parse("Take medicine every 2 days at 8am", now: referenceNow())

        XCTAssertEqual(event.title, "Take medicine")
        XCTAssertEqual(event.recurrence?.frequency, .daily)
        XCTAssertEqual(event.recurrence?.interval, 2)
        XCTAssertFalse(event.ambiguities.contains(.missingDate))
        XCTAssertEqual(parts(try XCTUnwrap(event.date)).hour, 8)
    }

    func testAmbiguousNumericDateRequiresClarification() {
        let parser = EventTextParser(calendar: utcCalendar())
        let event = parser.parse("Project review 03/04 at 10:00", now: referenceNow())

        XCTAssertNil(event.date)
        XCTAssertTrue(event.ambiguities.contains(.ambiguousNumericDate))
    }

    func testISODateIsDeterministic() throws {
        let parser = EventTextParser(calendar: utcCalendar())
        let event = parser.parse("Project review 2026-07-20 at 10:00", now: referenceNow())
        let components = parts(try XCTUnwrap(event.date))

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 7)
        XCTAssertEqual(components.day, 20)
        XCTAssertFalse(event.ambiguities.contains(.ambiguousNumericDate))
    }

    func testUnambiguousNumericDatesDoNotGuessLocaleOrder() throws {
        let parser = EventTextParser(calendar: utcCalendar())
        let dayFirst = parser.parse("Review 13/04/2026 at 10:00", now: referenceNow())
        let monthFirst = parser.parse("Review 04/13/2026 at 10:00", now: referenceNow())

        let firstComponents = parts(try XCTUnwrap(dayFirst.date))
        let secondComponents = parts(try XCTUnwrap(monthFirst.date))
        XCTAssertEqual(firstComponents.month, 4)
        XCTAssertEqual(firstComponents.day, 13)
        XCTAssertEqual(secondComponents.month, 4)
        XCTAssertEqual(secondComponents.day, 13)
    }

    func testInvalidDateIsNotNormalizedSilently() {
        let parser = EventTextParser(calendar: utcCalendar())
        let event = parser.parse("Submit report 31/02/2026 at 10:00", now: referenceNow())

        XCTAssertNil(event.date)
        XCTAssertTrue(event.ambiguities.contains(.invalidDate))
    }

    func testDaylightSavingGapIsFlagged() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .gmt
        let now = calendar.date(from: DateComponents(
            year: 2026,
            month: 3,
            day: 7,
            hour: 12
        )) ?? Date(timeIntervalSince1970: 0)
        let parser = EventTextParser(calendar: calendar)

        let event = parser.parse("Call Mum 8 March at 2:30am", now: now)

        XCTAssertTrue(event.ambiguities.contains(.daylightSavingAdjustment))
    }
}
