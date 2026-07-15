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
