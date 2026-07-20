import LifePilotCore
import LifePilotGhostBrain
import XCTest
@testable import LifePilotFeatures

@MainActor
final class QuickCaptureAndLoadableReferenceTests: XCTestCase {
    /// Reference feature states for Tasks (#38).
    func testTasksViewModelEmptyState() async {
        let store = FakeTasks()
        let viewModel = TasksViewModel(taskStore: store)
        await viewModel.setFilter(.today)
        XCTAssertTrue(viewModel.tasks.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testTasksViewModelLoadedFromDenseFixture() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let store = FakeTasks(seed: PreviewFixturesProxy.dense(relativeTo: now))
        let viewModel = TasksViewModel(taskStore: store, clock: FixedClock(now))
        await viewModel.setFilter(.upcoming)
        XCTAssertFalse(viewModel.tasks.isEmpty)
    }

    func testQuickCaptureParsesIntoEditableReview() {
        let now = Date(timeIntervalSince1970: 1_767_614_400)
        let viewModel = makeCaptureViewModel(now: now)
        viewModel.inputText = "Dentist tomorrow at 2:30pm at Baker Street"

        viewModel.prepareReview()

        XCTAssertTrue(viewModel.isReviewing)
        XCTAssertEqual(viewModel.title, "Dentist")
        XCTAssertEqual(viewModel.location, "Baker Street")
        XCTAssertTrue(viewModel.hasSchedule)
        XCTAssertTrue(viewModel.canSave)
    }

    func testAmbiguousCaptureBlocksCommitUntilUserConfirmsCorrection() {
        let viewModel = makeCaptureViewModel()
        viewModel.destination = .event
        viewModel.inputText = "Project review 03/04 at 10:00"

        viewModel.prepareReview()

        XCTAssertTrue(viewModel.ambiguities.contains(.ambiguousNumericDate))
        XCTAssertFalse(viewModel.canSave)

        viewModel.hasSchedule = true
        viewModel.ambiguityConfirmed = true
        XCTAssertTrue(viewModel.canSave)
    }

    func testQuickCaptureSavesLocalTaskOffline() async {
        let tasks = FakeTasks()
        let viewModel = makeCaptureViewModel(tasks: tasks)
        viewModel.inputText = "Write the project outline"
        viewModel.prepareReview()
        viewModel.notes = "Draft locally"

        let message = await viewModel.save()
        let saved = await tasks.allTasks()

        XCTAssertEqual(message, "Saved to your LifePilot Inbox.")
        XCTAssertEqual(saved.map(\.title), ["Write the project outline"])
        XCTAssertEqual(saved.first?.notes, "Draft locally")
    }

    func testQuickCapturePreservesParsedRecurrenceWhenSaving() async {
        let tasks = FakeTasks()
        let viewModel = makeCaptureViewModel(tasks: tasks)
        viewModel.inputText = "Review priorities every 2 days at 9am"
        viewModel.prepareReview()

        _ = await viewModel.save()
        let saved = await tasks.allTasks()

        XCTAssertEqual(saved.first?.recurrence?.frequency, .daily)
        XCTAssertEqual(saved.first?.recurrence?.interval, 2)
    }

    func testQuickCaptureSavesEditedLocalEventOffline() async {
        let events = FakeEvents()
        let viewModel = makeCaptureViewModel(events: events)
        viewModel.destination = .event
        viewModel.inputText = "Team review tomorrow at 4pm"
        viewModel.prepareReview()
        viewModel.title = "Edited team review"

        let message = await viewModel.save()
        let saved = await events.allEvents()

        XCTAssertEqual(message, "Saved as a local LifePilot event.")
        XCTAssertEqual(saved.map(\.title), ["Edited team review"])
    }

    func testAppleReminderQueuesBoundApprovalWithoutLocalWrite() async {
        let tasks = FakeTasks()
        let approvals = InMemoryApprovalStore()
        let viewModel = makeCaptureViewModel(tasks: tasks, approvals: approvals)
        viewModel.destination = .reminder
        viewModel.inputText = "Call Mum tomorrow at 6pm"
        viewModel.prepareReview()

        let message = await viewModel.save()
        let localTasks = await tasks.allTasks()
        let pending = await approvals.all()

        XCTAssertEqual(message, "Apple Reminder is ready for your approval.")
        XCTAssertTrue(localTasks.isEmpty)
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.0.actionType, .createEventKitReminder)
        XCTAssertEqual(pending.first?.1.state, .pending)
        XCTAssertEqual(
            pending.first?.0.parameterFingerprint,
            pending.first?.1.boundFingerprint
        )
    }

    func testAppleReminderRequiresOperatingSystemAuthorization() async {
        let approvals = InMemoryApprovalStore()
        let viewModel = makeCaptureViewModel(
            approvals: approvals,
            reminders: CaptureReminders(state: .denied)
        )
        viewModel.destination = .reminder
        viewModel.inputText = "Call Mum tomorrow at 6pm"
        viewModel.prepareReview()

        let message = await viewModel.save()
        let pending = await approvals.all()

        XCTAssertNil(message)
        XCTAssertTrue(pending.isEmpty)
        XCTAssertTrue(viewModel.errorMessage?.contains("Connect Apple Reminders") == true)
    }

    private func makeCaptureViewModel(
        tasks: any TaskStore = FakeTasks(),
        events: any EventStore = FakeEvents(),
        approvals: any ApprovalStore = InMemoryApprovalStore(),
        reminders: any RemindersIntegrating = CaptureReminders(),
        now: Date = Date(timeIntervalSince1970: 1_767_614_400)
    ) -> QuickCaptureViewModel {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return QuickCaptureViewModel(
            dependencies: QuickCaptureDependencies(
                taskStore: tasks,
                eventStore: events,
                approvalStore: approvals,
                reminders: reminders,
                parser: EventTextParser(calendar: calendar),
                clock: FixedClock(now)
            )
        )
    }
}

/// Minimal mirror so Features tests do not depend on LifePilotMocks directly
/// for CI layering, while still exercising dense fixtures.
private enum PreviewFixturesProxy {
    static func dense(relativeTo now: Date) -> [TaskItem] {
        (0 ..< 8).map { index in
            TaskItem(
                title: "Fixture \(index)",
                dueDate: now.addingTimeInterval(Double(index + 1) * 3600),
                priority: .normal
            )
        }
    }
}

private actor FakeTasks: TaskStore {
    private var items: [TaskItem]

    init(seed: [TaskItem] = []) {
        items = seed
    }

    func allTasks() async -> [TaskItem] {
        items
    }

    func save(_ task: TaskItem) async throws {
        if let index = items.firstIndex(where: { $0.id == task.id }) {
            items[index] = task
        } else {
            items.append(task)
        }
    }

    func delete(id: UUID) async throws {
        items.removeAll { $0.id == id }
    }

    func tasks(matching predicate: @Sendable (TaskItem) -> Bool) async -> [TaskItem] {
        items.filter(predicate)
    }
}

private actor FakeEvents: EventStore {
    private var items: [CalendarEvent] = []

    func allEvents() async -> [CalendarEvent] {
        items
    }

    func save(_ event: CalendarEvent) async throws {
        if let index = items.firstIndex(where: { $0.id == event.id }) {
            items[index] = event
        } else {
            items.append(event)
        }
    }

    func delete(id: UUID) async throws {
        items.removeAll { $0.id == id }
    }

    func events(from start: Date, to end: Date) async -> [CalendarEvent] {
        items.filter { $0.endDate >= start && $0.startDate <= end }
    }
}

private actor CaptureReminders: RemindersIntegrating {
    private let state: CapabilityState

    init(state: CapabilityState = .authorized) {
        self.state = state
    }

    func authorizationState() async -> CapabilityState {
        state
    }

    func requestAccess() async throws -> Bool {
        true
    }

    func fetchOpenReminders() async throws -> [TaskItem] {
        []
    }
}
