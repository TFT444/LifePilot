import Foundation
import LifePilotCore

/// Dense / empty / denied fixtures for previews and tests (#38).
public enum PreviewFixtures {
    public static func denseTasks(relativeTo now: Date = Date()) -> [TaskItem] {
        (0 ..< 12).map { index in
            TaskItem(
                title: "Task \(index + 1)",
                dueDate: now.addingTimeInterval(Double(index) * 1800),
                priority: index % 3 == 0 ? .high : .normal,
                context: index.isMultiple(of: 2) ? .work : .personal
            )
        }
    }

    public static func emptyTasks() -> [TaskItem] {
        []
    }

    public static func denseEvents(relativeTo now: Date = Date()) -> [CalendarEvent] {
        let calendar = Calendar.current
        return (9 ..< 18).map { hour in
            let start = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) ?? now
            return CalendarEvent(
                title: "Block \(hour):00",
                startDate: start,
                endDate: start.addingTimeInterval(2700),
                context: hour < 17 ? .work : .personal,
                eventKind: .meeting
            )
        }
    }

    public static func conflictingEvents(relativeTo now: Date = Date()) -> [CalendarEvent] {
        [
            CalendarEvent(
                title: "Sync",
                startDate: now,
                endDate: now.addingTimeInterval(3600),
                context: .work,
                eventKind: .meeting
            ),
            CalendarEvent(
                title: "Pickup",
                startDate: now.addingTimeInterval(1800),
                endDate: now.addingTimeInterval(5400),
                context: .personal
            ),
        ]
    }
}
