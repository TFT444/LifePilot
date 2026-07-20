import Foundation
import LifePilotCore
import LifePilotGhostBrain

public struct QuickCaptureDependencies: Sendable {
    public var taskStore: any TaskStore
    public var eventStore: any EventStore
    public var approvalStore: any ApprovalStore
    public var reminders: any RemindersIntegrating
    public var parser: EventTextParser
    public var clock: any ClockProviding

    public init(
        taskStore: any TaskStore,
        eventStore: any EventStore,
        approvalStore: any ApprovalStore,
        reminders: any RemindersIntegrating = UnavailableRemindersIntegration(),
        parser: EventTextParser = EventTextParser(),
        clock: any ClockProviding = SystemClock()
    ) {
        self.taskStore = taskStore
        self.eventStore = eventStore
        self.approvalStore = approvalStore
        self.reminders = reminders
        self.parser = parser
        self.clock = clock
    }
}

public enum CaptureRecurrenceChoice: String, CaseIterable, Sendable {
    case none
    case daily
    case weekly
    case monthly
    case yearly

    public var displayName: String {
        rawValue.capitalized
    }
}

@Observable
@MainActor
public final class QuickCaptureViewModel {
    public var inputText = ""
    public var destination: AppRoute.QuickCaptureKind
    public var title = ""
    public var notes = ""
    public var location = ""
    public var hasSchedule = false
    public var scheduledAt: Date
    public var recurrence: CaptureRecurrenceChoice = .none
    public var recurrenceInterval = 1
    public var ambiguityConfirmed = false

    public private(set) var isReviewing = false
    public private(set) var isSaving = false
    public private(set) var ambiguities: [CaptureAmbiguity] = []
    public private(set) var errorMessage: String?

    private let dependencies: QuickCaptureDependencies
    private var recurrenceDays: [Int] = []

    public init(
        dependencies: QuickCaptureDependencies,
        initialDestination: AppRoute.QuickCaptureKind = .task
    ) {
        self.dependencies = dependencies
        destination = initialDestination
        scheduledAt = dependencies.clock.now().addingTimeInterval(3600)
    }

    public var canReview: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var canSave: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let scheduleIsValid = destination != .event || hasSchedule
        let recurrenceIsValid = recurrence == .none || hasSchedule
        let ambiguityIsResolved = ambiguities.isEmpty || ambiguityConfirmed
        return hasTitle && scheduleIsValid && recurrenceIsValid && ambiguityIsResolved && !isSaving
    }

    public func prepareReview() {
        guard canReview else { return }
        let parsed = dependencies.parser.parse(inputText, now: dependencies.clock.now())
        title = parsed.title
        notes = parsed.details ?? ""
        location = parsed.location ?? ""
        hasSchedule = parsed.date != nil
        scheduledAt = parsed.date ?? dependencies.clock.now().addingTimeInterval(3600)
        recurrence = Self.choice(from: parsed.recurrence)
        recurrenceInterval = parsed.recurrence?.interval ?? 1
        recurrenceDays = parsed.recurrence?.daysOfWeek ?? []
        ambiguities = parsed.ambiguities.sorted { $0.rawValue < $1.rawValue }
        ambiguityConfirmed = ambiguities.isEmpty
        errorMessage = nil
        isReviewing = true
    }

    public func editOriginalText() {
        isReviewing = false
        errorMessage = nil
    }

    public func save() async -> String? {
        guard canSave else { return nil }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            switch destination {
            case .task:
                try await saveLocalTask()
                return "Saved to your LifePilot Inbox."
            case .event:
                try await saveLocalEvent()
                return "Saved as a local LifePilot event."
            case .reminder:
                try await queueAppleReminder()
                return "Apple Reminder is ready for your approval."
            }
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func saveLocalTask() async throws {
        try await dependencies.taskStore.save(
            TaskItem(
                title: normalizedTitle,
                notes: normalized(notes),
                dueDate: hasSchedule ? scheduledAt : nil,
                listID: TaskList.inbox.id,
                recurrence: recurrenceRule
            )
        )
    }

    private func saveLocalEvent() async throws {
        guard hasSchedule else {
            throw DomainError.validationFailed(field: "startDate")
        }
        try await dependencies.eventStore.save(
            CalendarEvent(
                title: normalizedTitle,
                notes: normalized(notes),
                location: normalized(location),
                startDate: scheduledAt,
                endDate: scheduledAt.addingTimeInterval(3600),
                recurrence: recurrenceRule
            )
        )
    }

    private func queueAppleReminder() async throws {
        let authorization = await dependencies.reminders.authorizationState()
        guard authorization == .authorized || authorization == .limited else {
            throw DomainError.unauthorizedNamed(
                "Connect Apple Reminders in Settings before creating an external reminder."
            )
        }
        var parameters = ["title": normalizedTitle]
        parameters["notes"] = normalized(notes)
        parameters["location"] = normalized(location)
        if hasSchedule {
            parameters["dueDate"] = Self.iso8601(scheduledAt)
        }
        if let recurrenceRule {
            parameters["recurrenceFrequency"] = recurrenceRule.frequency.rawValue
            parameters["recurrenceInterval"] = String(recurrenceRule.interval)
            if !recurrenceRule.daysOfWeek.isEmpty {
                parameters["recurrenceDays"] = recurrenceRule.daysOfWeek.map(String.init).joined(separator: ",")
            }
        }

        let proposal = ActionProposal(
            actionType: .createEventKitReminder,
            title: "Create Apple Reminder: \(normalizedTitle)",
            detail: "Review the parsed reminder before LifePilot writes to Apple Reminders.",
            parameters: parameters,
            riskLevel: .low
        )
        let record = ApprovalRecord(
            proposalID: proposal.id,
            boundFingerprint: proposal.parameterFingerprint
        )
        try await dependencies.approvalStore.save(proposal: proposal, record: record)
    }

    private var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var recurrenceRule: RecurrenceRule? {
        switch recurrence {
        case .none: nil
        case .daily: RecurrenceRule(frequency: .daily, interval: recurrenceInterval)
        case .weekly:
            RecurrenceRule(
                frequency: .weekly,
                interval: recurrenceInterval,
                daysOfWeek: recurrenceDays
            )
        case .monthly: RecurrenceRule(frequency: .monthly, interval: recurrenceInterval)
        case .yearly: RecurrenceRule(frequency: .yearly, interval: recurrenceInterval)
        }
    }

    private static func choice(from rule: RecurrenceRule?) -> CaptureRecurrenceChoice {
        guard let rule else { return .none }
        switch rule.frequency {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
    }

    private static func iso8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private func normalized(_ value: String) -> String? {
        let result = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }
}
