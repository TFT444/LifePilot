import EventKit
import Foundation
import LifePilotCore

/// EventKit calendar adapter behind `CalendarIntegrating`.
public final class EventKitCalendarIntegration: CalendarIntegrating, @unchecked Sendable {
    private let store: EKEventStore

    public init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    public func authorizationState() async -> CapabilityState {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .fullAccess: return .authorized
        case .writeOnly: return .limited
        case .authorized: return .authorized
        @unknown default: return .unavailable
        }
    }

    public func requestAccess() async throws -> Bool {
        try await store.requestFullAccessToEvents()
    }

    public func fetchEvents(from start: Date, to end: Date) async throws -> [CalendarEvent] {
        let state = await authorizationState()
        guard state == .authorized || state == .limited else {
            throw DomainError.unavailableNamed("Calendar access denied")
        }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).map { event in
            CalendarEvent(
                id: UUID(),
                title: event.title ?? "Untitled",
                notes: event.notes,
                location: event.location,
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay,
                attendeeCount: event.attendees?.count ?? 0,
                context: .personal,
                eventKind: .meeting,
                source: .eventKitCalendar,
                externalIdentifier: event.eventIdentifier,
                syncState: .synced,
                status: .confirmed
            )
        }
    }
}

/// EventKit reminders adapter behind `RemindersIntegrating`.
public final class EventKitRemindersIntegration: RemindersIntegrating, @unchecked Sendable {
    private let store: EKEventStore

    public init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    public func authorizationState() async -> CapabilityState {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .fullAccess: return .authorized
        case .writeOnly: return .limited
        case .authorized: return .authorized
        @unknown default: return .unavailable
        }
    }

    public func requestAccess() async throws -> Bool {
        try await store.requestFullAccessToReminders()
    }

    public func fetchOpenReminders() async throws -> [TaskItem] {
        let state = await authorizationState()
        guard state == .authorized || state == .limited else {
            throw DomainError.unavailableNamed("Reminders access denied")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = store.predicateForReminders(in: nil)
            store.fetchReminders(matching: predicate) { reminders in
                let mapped = (reminders ?? [])
                    .filter { !$0.isCompleted }
                    .map { reminder in
                        TaskItem(
                            title: reminder.title ?? "Reminder",
                            notes: reminder.notes,
                            dueDate: reminder.dueDateComponents?.date,
                            isCompleted: reminder.isCompleted,
                            completedAt: reminder.completionDate,
                            recurrence: reminder.recurrenceRules?.first.flatMap(Self.domainRule),
                            source: .eventKitReminders,
                            externalIdentifier: reminder.calendarItemExternalIdentifier,
                            syncState: .synced
                        )
                    }
                continuation.resume(returning: mapped)
            }
        }
    }

    public func createReminder(
        title: String,
        notes: String?,
        dueDate: Date?,
        recurrence: RecurrenceRule?
    ) async throws -> String {
        let state = await authorizationState()
        guard state == .authorized || state == .limited else {
            throw DomainError.unavailableNamed("Reminders access denied")
        }

        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = notes
        guard let calendar = store.defaultCalendarForNewReminders() else {
            throw DomainError.unavailableNamed("No writable Reminders list is available")
        }
        reminder.calendar = calendar
        if let dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.calendar, .timeZone, .year, .month, .day, .hour, .minute],
                from: dueDate
            )
        }
        if let recurrence {
            reminder.addRecurrenceRule(Self.eventKitRule(from: recurrence))
        }
        try store.save(reminder, commit: true)
        let identifier = reminder.calendarItemExternalIdentifier
        guard !identifier.isEmpty else {
            throw DomainError.invalidState("EventKit did not return a reminder identifier.")
        }
        return identifier
    }

    private static func eventKitRule(from rule: RecurrenceRule) -> EKRecurrenceRule {
        let frequency: EKRecurrenceFrequency = switch rule.frequency {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
        let days = rule.daysOfWeek.isEmpty
            ? nil
            : rule.daysOfWeek.map { EKRecurrenceDayOfWeek(EKWeekday(rawValue: $0) ?? .monday) }
        let end = rule.endDate.map { EKRecurrenceEnd(end: $0) }
        return EKRecurrenceRule(
            recurrenceWith: frequency,
            interval: rule.interval,
            daysOfTheWeek: days,
            daysOfTheMonth: nil,
            monthsOfTheYear: nil,
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: nil,
            end: end
        )
    }

    private static func domainRule(from rule: EKRecurrenceRule) -> RecurrenceRule? {
        let frequency: RecurrenceRule.Frequency = switch rule.frequency {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        @unknown default: return nil
        }
        return RecurrenceRule(
            frequency: frequency,
            interval: rule.interval,
            daysOfWeek: rule.daysOfTheWeek?.map { $0.dayOfTheWeek.rawValue } ?? [],
            endDate: rule.recurrenceEnd?.endDate
        )
    }
}
