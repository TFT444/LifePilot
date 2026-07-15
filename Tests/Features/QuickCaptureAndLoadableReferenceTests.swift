import LifePilotCore
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

    func testTasksViewModelLoadedFromDenseFixture() async throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let store = FakeTasks(seed: PreviewFixturesProxy.dense(relativeTo: now))
        let viewModel = TasksViewModel(taskStore: store, clock: FixedClock(now))
        await viewModel.setFilter(.upcoming)
        XCTAssertFalse(viewModel.tasks.isEmpty)
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
