import Foundation
import LifePilotCore

/// Realistic sample task/reminder data for previews, tests, and Phase 3's
/// mock-driven screens.
public enum MockTasks {
    public static func items(relativeTo now: Date = Date()) -> [TaskItem] {
        [
            TaskItem(
                title: "Send updated deck to the board",
                dueDate: now.addingTimeInterval(3 * 3600),
                priority: .high
            ),
            TaskItem(
                title: "Renew passport before the trip",
                dueDate: now.addingTimeInterval(14 * 24 * 3600),
                priority: .normal
            ),
            TaskItem(
                title: "Pick up dry cleaning",
                dueDate: now.addingTimeInterval(6 * 3600),
                priority: .low
            ),
            TaskItem(
                title: "Book dentist appointment",
                dueDate: nil,
                isCompleted: true,
                priority: .low
            ),
        ]
    }
}
