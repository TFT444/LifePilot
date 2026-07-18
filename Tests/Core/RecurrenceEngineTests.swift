import Foundation
import XCTest
@testable import LifePilotCore

final class RecurrenceEngineTests: XCTestCase {
    func testDailyNextOccurrence() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let rule = RecurrenceRule(frequency: .daily, interval: 1)
        let next = RecurrenceEngine.nextOccurrence(after: start, rule: rule)
        XCTAssertEqual(next?.timeIntervalSince(start), 86_400)
    }

    func testSkipOneAdvancesDueDate() {
        let due = Date(timeIntervalSince1970: 1_700_000_000)
        let task = TaskItem(
            title: "Standup notes",
            dueDate: due,
            recurrence: RecurrenceRule(frequency: .daily)
        )
        let skipped = RecurrenceEngine.skipOne(task, now: due)
        XCTAssertEqual(skipped?.dueDate?.timeIntervalSince(due), 86_400)
        XCTAssertNotNil(skipped?.recurrence)
    }

    func testRescheduleThisOccurrenceDetachesSeries() {
        let due = Date(timeIntervalSince1970: 1_700_000_000)
        let task = TaskItem(
            title: "Weekly review",
            dueDate: due,
            recurrence: RecurrenceRule(frequency: .weekly)
        )
        let newDue = due.addingTimeInterval(3600)
        let updated = RecurrenceEngine.reschedule(
            task,
            to: newDue,
            scope: .thisOccurrenceOnly,
            now: due
        )
        XCTAssertEqual(updated.dueDate, newDue)
        XCTAssertNil(updated.recurrence)
        XCTAssertEqual(updated.parentID, task.id)
    }

    func testRescheduleSeriesKeepsRule() {
        let due = Date(timeIntervalSince1970: 1_700_000_000)
        let task = TaskItem(
            title: "Weekly review",
            dueDate: due,
            recurrence: RecurrenceRule(frequency: .weekly)
        )
        let newDue = due.addingTimeInterval(3600)
        let updated = RecurrenceEngine.reschedule(
            task,
            to: newDue,
            scope: .entireSeries,
            now: due
        )
        XCTAssertEqual(updated.dueDate, newDue)
        XCTAssertNotNil(updated.recurrence)
    }

    func testExpandCapsResults() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let dates = RecurrenceEngine.expand(
            startingFrom: start,
            rule: RecurrenceRule(frequency: .daily),
            limit: 5
        )
        XCTAssertEqual(dates.count, 5)
    }
}
