import Foundation
import LifePilotCore
import XCTest
@testable import LifePilotFeatures

final class TaskNotificationCoordinatorTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_753_000_000)

    func testSchedulesPrivateDeterministicNotificationAndReschedulesAfterEdit() async {
        let scheduler = RecordingNotificationScheduler(state: .authorized)
        let preferences = NotificationPreferenceStore(
            preferences: UserPreferences(
                quietHoursStart: nil,
                quietHoursEnd: nil,
                sensitiveNotificationPreviews: false
            )
        )
        let coordinator = TaskNotificationCoordinator(
            scheduler: scheduler,
            preferenceStore: preferences,
            clock: FixedNotificationClock(now)
        )
        var task = TaskItem(title: "Private medical appointment", dueDate: now.addingTimeInterval(3600))

        await coordinator.reconcile(task)
        task.dueDate = now.addingTimeInterval(7200)
        await coordinator.reconcile(task)

        let requests = await scheduler.requests()
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(
            requests.map(\.id),
            Array(repeating: TaskNotificationCoordinator.identifier(for: task.id), count: 2)
        )
        XCTAssertEqual(requests.last?.body, "Open LifePilot to review what is due.")
        XCTAssertEqual(requests.last?.fireDate, task.dueDate)
    }

    func testCompletionAndRevokedPermissionCancelObsoleteNotification() async {
        let scheduler = RecordingNotificationScheduler(state: .authorized)
        let preferences = NotificationPreferenceStore(preferences: UserPreferences())
        let coordinator = TaskNotificationCoordinator(
            scheduler: scheduler,
            preferenceStore: preferences,
            clock: FixedNotificationClock(now)
        )
        var task = TaskItem(title: "Submit report", dueDate: now.addingTimeInterval(3600))
        await coordinator.reconcile(task)
        task.isCompleted = true
        await coordinator.reconcile(task)
        await scheduler.setState(.denied)
        task.isCompleted = false
        await coordinator.reconcile(task)

        let cancelled = await scheduler.cancelledIDs()
        XCTAssertEqual(cancelled.count, 2)
        XCTAssertTrue(cancelled.allSatisfy { $0 == TaskNotificationCoordinator.identifier(for: task.id) })
    }

    func testQuietHoursMoveNotificationToEndAndSensitivePreviewIsOptIn() async throws {
        let scheduler = RecordingNotificationScheduler(state: .authorized)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let preferences = NotificationPreferenceStore(
            preferences: UserPreferences(
                quietHoursStart: 22,
                quietHoursEnd: 7,
                sensitiveNotificationPreviews: true
            )
        )
        let coordinator = TaskNotificationCoordinator(
            scheduler: scheduler,
            preferenceStore: preferences,
            clock: FixedNotificationClock(now),
            calendar: calendar
        )
        let due = try XCTUnwrap(
            calendar.date(from: DateComponents(
                timeZone: calendar.timeZone,
                year: 2026,
                month: 7,
                day: 21,
                hour: 23
            ))
        )
        let task = TaskItem(title: "Call the clinic", dueDate: due)

        await coordinator.reconcile(task)

        let requests = await scheduler.requests()
        let request = try XCTUnwrap(requests.last)
        XCTAssertEqual(request.body, task.title)
        XCTAssertEqual(calendar.component(.hour, from: request.fireDate), 7)
        XCTAssertEqual(calendar.component(.day, from: request.fireDate), 22)
    }

    func testOverdueRecurringTaskSchedulesNextOccurrenceButOneOffDoesNot() async throws {
        let scheduler = RecordingNotificationScheduler(state: .authorized)
        let coordinator = TaskNotificationCoordinator(
            scheduler: scheduler,
            preferenceStore: NotificationPreferenceStore(preferences: UserPreferences()),
            clock: FixedNotificationClock(now)
        )
        let recurring = TaskItem(
            title: "Daily review",
            dueDate: now.addingTimeInterval(-3600),
            recurrence: RecurrenceRule(frequency: .daily)
        )
        let oneOff = TaskItem(title: "Old deadline", dueDate: now.addingTimeInterval(-3600))

        await coordinator.reconcile(recurring)
        await coordinator.reconcile(oneOff)

        let requests = await scheduler.requests()
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.id, TaskNotificationCoordinator.identifier(for: recurring.id))
        let request = try XCTUnwrap(requests.first)
        XCTAssertGreaterThan(request.fireDate, now)
        let cancelled = await scheduler.cancelledIDs()
        XCTAssertTrue(cancelled.contains(TaskNotificationCoordinator.identifier(for: oneOff.id)))
    }

    func testRelaunchReconciliationIgnoresAppleOwnedReminders() async {
        let scheduler = RecordingNotificationScheduler(state: .authorized)
        let coordinator = TaskNotificationCoordinator(
            scheduler: scheduler,
            preferenceStore: NotificationPreferenceStore(preferences: UserPreferences()),
            clock: FixedNotificationClock(now)
        )
        let local = TaskItem(title: "Local", dueDate: now.addingTimeInterval(3600))
        let apple = TaskItem(
            title: "Apple owned",
            dueDate: now.addingTimeInterval(3600),
            source: .eventKitReminders,
            externalIdentifier: "apple-id",
            syncState: .synced
        )

        await coordinator.reconcileAll([local, apple])

        let requests = await scheduler.requests()
        XCTAssertEqual(requests.map(\.id), [TaskNotificationCoordinator.identifier(for: local.id)])
    }
}

private struct NotificationRequest: Sendable {
    let id: String
    let title: String
    let body: String
    let fireDate: Date
}

private actor RecordingNotificationScheduler: NotificationScheduling {
    private var state: PermissionState
    private var recorded: [NotificationRequest] = []
    private var cancelled: [String] = []

    init(state: PermissionState) {
        self.state = state
    }

    func authorizationState() async -> PermissionState {
        state
    }

    func requestAuthorization() async throws -> Bool {
        state == .authorized
    }

    func schedule(id: String, title: String, body: String, fireDate: Date) async throws {
        recorded.append(NotificationRequest(id: id, title: title, body: body, fireDate: fireDate))
    }

    func cancel(id: String) async throws {
        cancelled.append(id)
    }

    func cancelAll() async throws {
        cancelled.removeAll()
    }

    func requests() -> [NotificationRequest] {
        recorded
    }

    func cancelledIDs() -> [String] {
        cancelled
    }

    func setState(_ state: PermissionState) {
        self.state = state
    }
}

private actor NotificationPreferenceStore: PreferenceStore {
    private var preferences: UserPreferences

    init(preferences: UserPreferences) {
        self.preferences = preferences
    }

    func loadPreferences() async -> UserPreferences {
        preferences
    }

    func savePreferences(_ preferences: UserPreferences) async throws {
        self.preferences = preferences
    }

    func allMemory() async -> [MemoryItem] {
        []
    }

    func saveMemory(_: MemoryItem) async throws {}

    func deleteMemory(id _: UUID) async throws {}

    func exportAll() async throws -> Data {
        Data()
    }

    func deleteAllLifePilotData() async throws {}
}

private struct FixedNotificationClock: ClockProviding {
    let value: Date

    init(_ value: Date) {
        self.value = value
    }

    func now() -> Date {
        value
    }
}
