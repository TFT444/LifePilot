import Foundation

/// Expands and mutates recurring task/event schedules. Supports skip-one and
/// edit-this vs edit-series without touching external calendars until approved.
public enum RecurrenceEngine: Sendable {
    public enum EditScope: String, Sendable, CaseIterable {
        case thisOccurrenceOnly
        case entireSeries
    }

    /// Next due date after `after`, respecting frequency/interval/end.
    public static func nextOccurrence(
        after date: Date,
        rule: RecurrenceRule,
        calendar: Calendar = .current
    ) -> Date? {
        var cursor = date
        for _ in 0 ..< 400 {
            guard let candidate = advance(cursor, rule: rule, calendar: calendar) else {
                return nil
            }
            if let end = rule.endDate, candidate > end {
                return nil
            }
            if rule.daysOfWeek.isEmpty || rule.frequency != .weekly {
                return candidate
            }
            let weekday = calendar.component(.weekday, from: candidate)
            if rule.daysOfWeek.contains(weekday) {
                return candidate
            }
            cursor = candidate
        }
        return nil
    }

    /// Skip the current occurrence and return an updated task with the next due date.
    public static func skipOne(_ task: TaskItem, now: Date = Date()) -> TaskItem? {
        guard let rule = task.recurrence else { return nil }
        let base = task.dueDate ?? now
        guard let next = nextOccurrence(after: base, rule: rule) else { return nil }
        var updated = task
        updated.dueDate = next
        updated.updatedAt = now
        return updated
    }

    /// Apply a due-date change either to this occurrence (detach) or the whole series.
    public static func reschedule(
        _ task: TaskItem,
        to newDue: Date,
        scope: EditScope,
        now: Date = Date()
    ) -> TaskItem {
        var updated = task
        updated.dueDate = newDue
        updated.updatedAt = now
        switch scope {
        case .thisOccurrenceOnly:
            // Detach from series so later instances keep the original rule.
            updated.recurrence = nil
            updated.parentID = task.parentID ?? task.id
        case .entireSeries:
            break
        }
        return updated
    }

    /// Expand upcoming occurrences for agenda/timeline (capped).
    public static func expand(
        startingFrom start: Date,
        rule: RecurrenceRule,
        limit: Int = 12,
        calendar: Calendar = .current
    ) -> [Date] {
        var results: [Date] = []
        var cursor = start.addingTimeInterval(-1)
        while results.count < limit {
            guard let next = nextOccurrence(after: cursor, rule: rule, calendar: calendar) else {
                break
            }
            results.append(next)
            cursor = next
        }
        return results
    }

    private static func advance(
        _ date: Date,
        rule: RecurrenceRule,
        calendar: Calendar
    ) -> Date? {
        switch rule.frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: rule.interval, to: date)
        case .weekly:
            if rule.daysOfWeek.isEmpty {
                return calendar.date(byAdding: .weekOfYear, value: rule.interval, to: date)
            }
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: rule.interval, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: rule.interval, to: date)
        }
    }
}
