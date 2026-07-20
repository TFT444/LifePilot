import Foundation
import XCTest
@testable import LifePilotCore

final class ApprovalSideEffectTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testRescheduleTaskUpdatesExistingTarget() async throws {
        let taskID = UUID()
        let taskStore = FakeTaskStore(seed: [TaskItem(id: taskID, title: "Prepare deck")])
        let dueDate = now.addingTimeInterval(7200)
        let executor = makeExecutor(taskStore: taskStore)
        let proposal = ActionProposal(
            actionType: .rescheduleLocalTask,
            title: "Reschedule task",
            detail: "Move the deadline",
            parameters: [
                "taskID": taskID.uuidString,
                "dueDate": iso8601(dueDate),
            ]
        )

        _ = try await executor.execute(proposal: proposal, approval: approved(proposal))

        let tasks = await taskStore.allTasks()
        let saved = try XCTUnwrap(tasks.first)
        XCTAssertEqual(saved.dueDate, dueDate)
        XCTAssertEqual(saved.updatedAt, now)
    }

    func testMissingTaskFailsInsteadOfReportingSuccess() async {
        let executor = makeExecutor()
        let proposal = ActionProposal(
            actionType: .completeLocalTask,
            title: "Complete task",
            detail: "Missing target",
            parameters: ["taskID": UUID().uuidString]
        )

        await assertDomainError(.notFoundNamed("Task")) {
            _ = try await executor.execute(
                proposal: proposal,
                approval: approved(proposal)
            )
        }
    }

    func testUpdateEventRequiresAndAppliesARealChange() async throws {
        let eventID = UUID()
        let original = CalendarEvent(
            id: eventID,
            title: "Planning",
            startDate: now,
            endDate: now.addingTimeInterval(3600)
        )
        let eventStore = FakeEventStore(seed: [original])
        let executor = makeExecutor(eventStore: eventStore)
        let proposal = ActionProposal(
            actionType: .updateLocalEvent,
            title: "Update event",
            detail: "Add a room",
            parameters: [
                "eventID": eventID.uuidString,
                "title": "Planning review",
                "location": "Room 4",
            ]
        )

        _ = try await executor.execute(proposal: proposal, approval: approved(proposal))

        let events = await eventStore.allEvents()
        let saved = try XCTUnwrap(events.first)
        XCTAssertEqual(saved.title, "Planning review")
        XCTAssertEqual(saved.location, "Room 4")
    }

    func testUpdateEventRejectsEmptyMutation() async {
        let eventID = UUID()
        let event = CalendarEvent(
            id: eventID,
            title: "Planning",
            startDate: now,
            endDate: now.addingTimeInterval(3600)
        )
        let executor = makeExecutor(eventStore: FakeEventStore(seed: [event]))
        let proposal = ActionProposal(
            actionType: .updateLocalEvent,
            title: "Update event",
            detail: "No fields",
            parameters: ["eventID": eventID.uuidString]
        )

        await assertDomainError(.validationFailed(field: "parameters")) {
            _ = try await executor.execute(
                proposal: proposal,
                approval: approved(proposal)
            )
        }
    }

    func testDeleteLocalRecordVerifiesTargetBeforeDeleting() async throws {
        let eventID = UUID()
        let event = CalendarEvent(
            id: eventID,
            title: "Remove me",
            startDate: now,
            endDate: now.addingTimeInterval(3600)
        )
        let eventStore = FakeEventStore(seed: [event])
        let executor = makeExecutor(eventStore: eventStore)
        let proposal = ActionProposal(
            actionType: .deleteLocalRecord,
            title: "Delete event",
            detail: "Approved deletion",
            parameters: [
                "recordID": eventID.uuidString,
                "recordType": "event",
            ]
        )

        _ = try await executor.execute(proposal: proposal, approval: approved(proposal))
        let events = await eventStore.allEvents()
        XCTAssertTrue(events.isEmpty)
    }

    func testNotificationScheduleAndCancelUseInjectedAdapter() async throws {
        let scheduler = FakeNotificationScheduler(state: .authorized)
        let executor = makeExecutor(notificationScheduler: scheduler)
        let notificationID = "briefing-ready"
        let schedule = ActionProposal(
            actionType: .scheduleNotification,
            title: "Briefing ready",
            detail: "Your day is prepared.",
            parameters: [
                "notificationID": notificationID,
                "fireDate": iso8601(now.addingTimeInterval(300)),
            ]
        )
        _ = try await executor.execute(proposal: schedule, approval: approved(schedule))
        let scheduledIDs = await scheduler.scheduledIDs()
        XCTAssertEqual(scheduledIDs, Set([notificationID]))

        let cancel = ActionProposal(
            actionType: .cancelNotification,
            title: "Cancel briefing",
            detail: "No longer needed",
            parameters: ["notificationID": notificationID]
        )
        _ = try await executor.execute(proposal: cancel, approval: approved(cancel))
        let cancelledIDs = await scheduler.cancelledIDs()
        XCTAssertEqual(cancelledIDs, Set([notificationID]))
    }

    func testNotificationScheduleRequiresAuthorization() async {
        let scheduler = FakeNotificationScheduler(state: .denied)
        let executor = makeExecutor(notificationScheduler: scheduler)
        let proposal = ActionProposal(
            actionType: .scheduleNotification,
            title: "Briefing ready",
            detail: "Your day is prepared.",
            parameters: ["fireDate": iso8601(now.addingTimeInterval(300))]
        )

        await assertDomainError(
            .unauthorizedNamed("Notification permission is not authorized.")
        ) {
            _ = try await executor.execute(
                proposal: proposal,
                approval: approved(proposal)
            )
        }
    }
}
