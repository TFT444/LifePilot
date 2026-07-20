import Foundation
import XCTest
@testable import LifePilotCore

final class ReminderTests: XCTestCase {
    func testFireDateSubtractsLeadTime() {
        let due = Date(timeIntervalSince1970: 10_000)
        let reminder = Reminder(title: "Dentist", dueDate: due, leadTime: 600)
        XCTAssertEqual(reminder.fireDate, due.addingTimeInterval(-600))
    }

    func testIsDueOnceFireDateReached() {
        let due = Date(timeIntervalSince1970: 10_000)
        let reminder = Reminder(title: "Dentist", dueDate: due, leadTime: 600)
        XCTAssertFalse(reminder.isDue(at: due.addingTimeInterval(-601)))
        XCTAssertTrue(reminder.isDue(at: due.addingTimeInterval(-600)))
        XCTAssertTrue(reminder.isDue(at: due))
    }

    func testCompletedReminderIsNeverDue() {
        let due = Date(timeIntervalSince1970: 10_000)
        let reminder = Reminder(title: "Dentist", dueDate: due, leadTime: 0, isCompleted: true)
        XCTAssertFalse(reminder.isDue(at: due.addingTimeInterval(100)))
    }

    func testTimeUntilDueNeverNegative() {
        let due = Date(timeIntervalSince1970: 10_000)
        let reminder = Reminder(title: "Dentist", dueDate: due)
        XCTAssertEqual(reminder.timeUntilDue(from: due.addingTimeInterval(-120)), 120)
        XCTAssertEqual(reminder.timeUntilDue(from: due.addingTimeInterval(500)), 0)
    }

    func testNegativeLeadTimeClampedToZero() {
        let reminder = Reminder(title: "X", dueDate: Date(), leadTime: -50)
        XCTAssertEqual(reminder.leadTime, 0)
    }
}

final class CapturedEventTests: XCTestCase {
    func testSchedulableRequiresDateAndTitle() {
        let withDate = CapturedEvent(title: "Meeting", date: Date())
        XCTAssertTrue(withDate.isSchedulable)

        let noDate = CapturedEvent(title: "Meeting", date: nil)
        XCTAssertFalse(noDate.isSchedulable)
    }

    func testMakeReminderCarriesFields() {
        let date = Date(timeIntervalSince1970: 50_000)
        let event = CapturedEvent(
            title: "Dentist",
            date: date,
            location: "Baker St",
            details: "Bring card",
            confidence: 0.9
        )
        let reminder = event.makeReminder(leadTime: 900)
        XCTAssertNotNil(reminder)
        XCTAssertEqual(reminder?.title, "Dentist")
        XCTAssertEqual(reminder?.dueDate, date)
        XCTAssertEqual(reminder?.location, "Baker St")
        XCTAssertEqual(reminder?.notes, "Bring card")
        XCTAssertEqual(reminder?.leadTime, 900)
    }

    func testMakeReminderNilWithoutDate() {
        let event = CapturedEvent(title: "Pay rent", date: nil)
        XCTAssertNil(event.makeReminder())
    }

    func testConfidenceClampedToUnitRange() {
        XCTAssertEqual(CapturedEvent(title: "A", confidence: 5).confidence, 1)
        XCTAssertEqual(CapturedEvent(title: "A", confidence: -2).confidence, 0)
    }
}

final class TransitModelTests: XCTestCase {
    func testEtaLabelDueWhenImminent() {
        let dep = TransitDeparture(lineName: "Victoria", destination: "Brixton", secondsToStation: 20)
        XCTAssertEqual(dep.etaLabel, "Due")
    }

    func testEtaLabelRoundsUpToMinutes() {
        let dep = TransitDeparture(lineName: "Victoria", destination: "Brixton", secondsToStation: 150)
        XCTAssertEqual(dep.minutesToDeparture, 3)
        XCTAssertEqual(dep.etaLabel, "3 min")
    }

    func testSeverityClassification() {
        XCTAssertEqual(TransitLineStatus.Severity.classify("Good Service"), .good)
        XCTAssertEqual(TransitLineStatus.Severity.classify("Minor Delays"), .minor)
        XCTAssertEqual(TransitLineStatus.Severity.classify("Severe Delays"), .severe)
        XCTAssertEqual(TransitLineStatus.Severity.classify("Part Suspended"), .severe)
    }

    func testSeverityOrdering() {
        XCTAssertTrue(TransitLineStatus.Severity.good < .minor)
        XCTAssertTrue(TransitLineStatus.Severity.minor < .severe)
    }
}
