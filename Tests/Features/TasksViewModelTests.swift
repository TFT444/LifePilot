import LifePilotCore
import XCTest
@testable import LifePilotFeatures

@MainActor
final class TasksViewModelTests: XCTestCase {
    func testQuickCaptureAddsTask() async throws {
        let store = FakeTasks()
        let viewModel = TasksViewModel(
            taskStore: store,
            clock: FixedClock(Date(timeIntervalSince1970: 1_700_000_000))
        )
        viewModel.draftTitle = "Buy oat milk"
        try await viewModel.quickCapture()
        await viewModel.setFilter(.inbox)
        XCTAssertEqual(viewModel.draftTitle, "")
        XCTAssertTrue(viewModel.tasks.contains { $0.title == "Buy oat milk" })
        XCTAssertTrue(viewModel.tasks.contains { $0.title == "Buy oat milk" && $0.dueDate == nil })
    }

    func testToggleCompletion() async throws {
        let task = TaskItem(title: "Done me", dueDate: Date())
        let store = FakeTasks(seed: [task])
        let viewModel = TasksViewModel(taskStore: store)
        await viewModel.setFilter(.today)
        try await viewModel.toggleCompletion(task)
        await viewModel.setFilter(.completed)
        XCTAssertTrue(viewModel.tasks.contains { $0.id == task.id && $0.isCompleted })
    }

    func testSkipOccurrenceAdvancesRecurringTask() async throws {
        let due = Date(timeIntervalSince1970: 1_700_000_000)
        let task = TaskItem(
            title: "Water plants",
            dueDate: due,
            recurrence: RecurrenceRule(frequency: .daily)
        )
        let store = FakeTasks(seed: [task])
        let viewModel = TasksViewModel(
            taskStore: store,
            clock: FixedClock(due)
        )
        await viewModel.setFilter(.scheduled)
        try await viewModel.skipOccurrence(task)
        let saved = await store.allTasks()
        XCTAssertEqual(saved.first?.dueDate?.timeIntervalSince(due), 86_400)
        XCTAssertNotNil(saved.first?.recurrence)
    }

    func testRescheduleThisOccurrenceDetaches() async throws {
        let due = Date(timeIntervalSince1970: 1_700_000_000)
        let task = TaskItem(
            title: "Weekly review",
            dueDate: due,
            recurrence: RecurrenceRule(frequency: .weekly)
        )
        let store = FakeTasks(seed: [task])
        let viewModel = TasksViewModel(taskStore: store, clock: FixedClock(due))
        let newDue = due.addingTimeInterval(86_400)
        try await viewModel.reschedule(task, to: newDue, scope: .thisOccurrenceOnly)
        let saved = await store.allTasks()
        XCTAssertNil(saved.first?.recurrence)
        XCTAssertEqual(saved.first?.dueDate, newDue)
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
