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
        case .restricted, .denied: return .denied
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
        case .restricted, .denied: return .denied
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
                            source: .eventKitReminders,
                            syncState: .synced
                        )
                    }
                continuation.resume(returning: mapped)
            }
        }
    }
}
