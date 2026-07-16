import Foundation
import LifePilotCore
import Observation

/// Task list screen state: Inbox / Today / Upcoming / Scheduled / Completed.
@Observable
@MainActor
public final class TasksViewModel {
    public private(set) var tasks: [TaskItem] = []
    public private(set) var filter: TaskFilter = .today
    public private(set) var isLoading = false
    public var draftTitle = ""
    public var searchText = ""

    private let taskStore: any TaskStore
    private let clock: any ClockProviding

    public init(taskStore: any TaskStore, clock: any ClockProviding = SystemClock()) {
        self.taskStore = taskStore
        self.clock = clock
    }

    public enum TaskFilter: String, CaseIterable, Sendable {
        case inbox
        case today
        case upcoming
        case scheduled
        case completed
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        let all = await taskStore.allTasks()
        let now = clock.now()
        let calendar = Calendar.current
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let filtered: [TaskItem]
        switch filter {
        case .inbox:
            filtered = all.filter { task in
                !task.isCompleted
                    && task.dueDate == nil
                    && (task.listID == nil || task.listID == TaskList.inbox.id)
            }
        case .today:
            filtered = all.filter { task in
                guard !task.isCompleted, let due = task.dueDate else { return false }
                return calendar.isDateInToday(due) || due < now
            }
        case .upcoming:
            filtered = all.filter { task in
                guard !task.isCompleted, let due = task.dueDate else { return false }
                return due > now && !calendar.isDateInToday(due)
            }
        case .scheduled:
            filtered = all.filter { task in
                !task.isCompleted && task.dueDate != nil
            }
        case .completed:
            filtered = all.filter(\.isCompleted)
        }

        if query.isEmpty {
            tasks = filtered
        } else {
            tasks = filtered.filter {
                $0.title.lowercased().contains(query)
                    || ($0.notes?.lowercased().contains(query) ?? false)
                    || $0.tags.contains { $0.lowercased().contains(query) }
            }
        }
    }

    public func setFilter(_ filter: TaskFilter) async {
        self.filter = filter
        await load()
    }

    public func quickCapture() async throws {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        // No arbitrary one-hour deadline — land in Inbox until the user schedules.
        let task = TaskItem(title: title, listID: TaskList.inbox.id)
        try await taskStore.save(task)
        draftTitle = ""
        await load()
    }

    public func toggleCompletion(_ task: TaskItem) async throws {
        var updated = task
        updated.isCompleted.toggle()
        updated.completedAt = updated.isCompleted ? clock.now() : nil
        updated.updatedAt = clock.now()
        try await taskStore.save(updated)
        await load()
    }

    public func snooze(_ task: TaskItem, by interval: TimeInterval) async throws {
        var updated = task
        let base = max(updated.dueDate ?? clock.now(), clock.now())
        updated.dueDate = base.addingTimeInterval(interval)
        updated.updatedAt = clock.now()
        try await taskStore.save(updated)
        await load()
    }

    public func delete(_ task: TaskItem) async throws {
        try await taskStore.delete(id: task.id)
        await load()
    }

    public func duplicate(_ task: TaskItem) async throws {
        let copy = TaskItem(
            title: task.title,
            notes: task.notes,
            dueDate: task.dueDate,
            startDate: task.startDate,
            priority: task.priority,
            tags: task.tags,
            listID: task.listID,
            estimatedDuration: task.estimatedDuration,
            context: task.context,
            recurrence: task.recurrence
        )
        try await taskStore.save(copy)
        await load()
    }
}
