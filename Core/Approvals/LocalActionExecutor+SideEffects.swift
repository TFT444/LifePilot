import Foundation

extension LocalActionExecutor {
    func applySideEffects(for proposal: ActionProposal) async throws {
        switch proposal.actionType {
        case .createLocalTask:
            try await createLocalTask(from: proposal)
        case .completeLocalTask:
            try await completeTask(from: proposal)
        case .rescheduleLocalTask:
            try await rescheduleTask(from: proposal)
        case .createLocalEvent:
            try await createLocalEvent(from: proposal)
        case .updateLocalEvent:
            try await updateLocalEvent(from: proposal)
        case .deleteLocalRecord:
            try await deleteLocalRecord(from: proposal)
        case .scheduleNotification:
            try await scheduleNotification(from: proposal)
        case .cancelNotification:
            try await cancelNotification(from: proposal)
        case .rescheduleEventKitEvent, .createEventKitReminder:
            guard case let .unsupported(reason) = policy.disposition(
                for: proposal.actionType
            ) else {
                throw DomainError.invalidState("External write is not connected yet.")
            }
            throw DomainError.invalidState(reason)
        case .forbiddenExternalFinancial, .forbiddenSendEmail:
            throw DomainError.unauthorized
        }
    }

    private func createLocalTask(from proposal: ActionProposal) async throws {
        let title = try requiredString("title", in: proposal, fallback: proposal.title)
        let dueDate = try optionalDate("dueDate", in: proposal)
        try await taskStore.save(
            TaskItem(
                id: proposal.id,
                title: title,
                notes: proposal.parameters["notes"],
                dueDate: dueDate,
                createdAt: proposal.createdAt,
                updatedAt: clock.now()
            )
        )
    }

    private func completeTask(from proposal: ActionProposal) async throws {
        var task = try await existingTask(from: proposal)
        task.isCompleted = true
        task.completedAt = clock.now()
        task.updatedAt = clock.now()
        try await taskStore.save(task)
    }

    private func rescheduleTask(from proposal: ActionProposal) async throws {
        var task = try await existingTask(from: proposal)
        task.dueDate = try requiredDate("dueDate", in: proposal)
        task.updatedAt = clock.now()
        try await taskStore.save(task)
    }

    private func existingTask(from proposal: ActionProposal) async throws -> TaskItem {
        let id = try requiredUUID("taskID", in: proposal)
        let tasks = await taskStore.allTasks()
        guard let task = tasks.first(where: { $0.id == id }) else {
            throw DomainError.notFoundNamed("Task")
        }
        return task
    }

    private func createLocalEvent(from proposal: ActionProposal) async throws {
        let title = try requiredString("title", in: proposal, fallback: proposal.title)
        let start = try optionalDate("startDate", in: proposal) ?? clock.now()
        let end = try optionalDate("endDate", in: proposal)
            ?? start.addingTimeInterval(3600)
        guard end > start else {
            throw DomainError.validationFailed(field: "endDate")
        }
        try await eventStore.save(
            CalendarEvent(
                id: proposal.id,
                title: title,
                notes: proposal.parameters["notes"],
                location: proposal.parameters["location"],
                startDate: start,
                endDate: end
            )
        )
    }

    private func updateLocalEvent(from proposal: ActionProposal) async throws {
        let id = try requiredUUID("eventID", in: proposal)
        let events = await eventStore.allEvents()
        guard var event = events.first(where: { $0.id == id }) else {
            throw DomainError.notFoundNamed("Event")
        }

        let textChanged = try applyTextChanges(to: &event, parameters: proposal.parameters)
        let dateChanged = try applyDateChanges(to: &event, proposal: proposal)
        let allDayChanged = try applyAllDayChange(to: &event, parameters: proposal.parameters)
        guard textChanged || dateChanged || allDayChanged else {
            throw DomainError.validationFailed(field: "parameters")
        }
        guard event.endDate > event.startDate else {
            throw DomainError.validationFailed(field: "endDate")
        }
        try await eventStore.save(event)
    }

    private func applyTextChanges(
        to event: inout CalendarEvent,
        parameters: [String: String]
    ) throws -> Bool {
        var changed = false
        if let title = parameters["title"] {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DomainError.validationFailed(field: "title")
            }
            event.title = title
            changed = true
        }
        if let notes = parameters["notes"] {
            event.notes = notes.isEmpty ? nil : notes
            changed = true
        }
        if let location = parameters["location"] {
            event.location = location.isEmpty ? nil : location
            changed = true
        }
        return changed
    }

    private func applyDateChanges(
        to event: inout CalendarEvent,
        proposal: ActionProposal
    ) throws -> Bool {
        var changed = false
        if proposal.parameters["startDate"] != nil {
            event.startDate = try requiredDate("startDate", in: proposal)
            changed = true
        }
        if proposal.parameters["endDate"] != nil {
            event.endDate = try requiredDate("endDate", in: proposal)
            changed = true
        }
        return changed
    }

    private func applyAllDayChange(
        to event: inout CalendarEvent,
        parameters: [String: String]
    ) throws -> Bool {
        guard let isAllDay = parameters["isAllDay"] else { return false }
        guard let parsed = Bool(isAllDay) else {
            throw DomainError.validationFailed(field: "isAllDay")
        }
        event.isAllDay = parsed
        return true
    }

    private func deleteLocalRecord(from proposal: ActionProposal) async throws {
        let id = try requiredUUID("recordID", in: proposal)
        let recordType = try requiredString("recordType", in: proposal).lowercased()
        switch recordType {
        case "task":
            guard (await taskStore.allTasks()).contains(where: { $0.id == id }) else {
                throw DomainError.notFoundNamed("Task")
            }
            try await taskStore.delete(id: id)
        case "event":
            guard (await eventStore.allEvents()).contains(where: { $0.id == id }) else {
                throw DomainError.notFoundNamed("Event")
            }
            try await eventStore.delete(id: id)
        default:
            throw DomainError.validationFailed(field: "recordType")
        }
    }

    private func scheduleNotification(from proposal: ActionProposal) async throws {
        guard let notificationScheduler else {
            throw DomainError.invalidState("Notification scheduling is not configured.")
        }
        guard await notificationScheduler.authorizationState() == .authorized else {
            throw DomainError.unauthorizedNamed("Notification permission is not authorized.")
        }
        let id = proposal.parameters["notificationID"] ?? proposal.id.uuidString
        let title = try requiredString("title", in: proposal, fallback: proposal.title)
        let body = proposal.parameters["body"] ?? proposal.detail
        let fireDate = try requiredDate("fireDate", in: proposal)
        try await notificationScheduler.schedule(
            id: id,
            title: title,
            body: body,
            fireDate: fireDate
        )
    }

    private func cancelNotification(from proposal: ActionProposal) async throws {
        guard let notificationScheduler else {
            throw DomainError.invalidState("Notification scheduling is not configured.")
        }
        let id = try requiredString("notificationID", in: proposal)
        try await notificationScheduler.cancel(id: id)
    }

    private func requiredUUID(_ key: String, in proposal: ActionProposal) throws -> UUID {
        let value = try requiredString(key, in: proposal)
        guard let id = UUID(uuidString: value) else {
            throw DomainError.validationFailed(field: key)
        }
        return id
    }

    private func requiredString(
        _ key: String,
        in proposal: ActionProposal,
        fallback: String? = nil
    ) throws -> String {
        let value = proposal.parameters[key] ?? fallback ?? ""
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw DomainError.validationFailed(field: key)
        }
        return trimmed
    }

    private func requiredDate(_ key: String, in proposal: ActionProposal) throws -> Date {
        guard let date = try optionalDate(key, in: proposal) else {
            throw DomainError.validationFailed(field: key)
        }
        return date
    }

    private func optionalDate(_ key: String, in proposal: ActionProposal) throws -> Date? {
        guard let value = proposal.parameters[key] else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: value) {
            return date
        }
        throw DomainError.validationFailed(field: key)
    }
}
