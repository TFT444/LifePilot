import Foundation
import LifePilotCore

/// Keeps one deterministic local notification in sync with each LifePilot-owned task.
public struct TaskNotificationCoordinator: Sendable {
    private let scheduler: any NotificationScheduling
    private let preferenceStore: any PreferenceStore
    private let clock: any ClockProviding
    private let calendar: Calendar

    public init(
        scheduler: any NotificationScheduling,
        preferenceStore: any PreferenceStore,
        clock: any ClockProviding = SystemClock(),
        calendar: Calendar = .current
    ) {
        self.scheduler = scheduler
        self.preferenceStore = preferenceStore
        self.clock = clock
        self.calendar = calendar
    }

    public func reconcile(_ task: TaskItem) async {
        let identifier = Self.identifier(for: task.id)
        guard await scheduler.authorizationState() == .authorized,
              !task.isCompleted,
              let fireDate = nextFireDate(for: task)
        else {
            try? await scheduler.cancel(id: identifier)
            return
        }

        let preferences = await preferenceStore.loadPreferences()
        let adjusted = adjustedForQuietHours(fireDate, preferences: preferences)
        let body = preferences.sensitiveNotificationPreviews
            ? task.title
            : "Open LifePilot to review what is due."
        try? await scheduler.schedule(
            id: identifier,
            title: "LifePilot reminder",
            body: body,
            fireDate: adjusted
        )
    }

    public func reconcileAll(_ tasks: [TaskItem]) async {
        for task in tasks where task.source == .local {
            await reconcile(task)
        }
    }

    public func cancel(taskID: UUID) async {
        try? await scheduler.cancel(id: Self.identifier(for: taskID))
    }

    public static func identifier(for taskID: UUID) -> String {
        "lifepilot.task.\(taskID.uuidString.lowercased())"
    }

    private func nextFireDate(for task: TaskItem) -> Date? {
        guard var dueDate = task.dueDate else { return nil }
        let now = clock.now()
        if dueDate <= now, let recurrence = task.recurrence {
            while dueDate <= now {
                guard let next = RecurrenceEngine.nextOccurrence(
                    after: dueDate,
                    rule: recurrence,
                    calendar: calendar
                ) else { return nil }
                dueDate = next
            }
        }
        return dueDate > now ? dueDate : nil
    }

    private func adjustedForQuietHours(
        _ date: Date,
        preferences: UserPreferences
    ) -> Date {
        guard let start = preferences.quietHoursStart,
              let end = preferences.quietHoursEnd,
              start != end
        else { return date }

        let hour = calendar.component(.hour, from: date)
        let isQuiet = start < end
            ? (start ..< end).contains(hour)
            : hour >= start || hour < end
        guard isQuiet else { return date }

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = end
        components.minute = 0
        components.second = 0
        guard var adjusted = calendar.date(from: components) else { return date }
        if start > end, hour >= start {
            adjusted = calendar.date(byAdding: .day, value: 1, to: adjusted) ?? adjusted
        }
        return adjusted
    }
}
