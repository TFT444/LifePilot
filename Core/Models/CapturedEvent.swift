import Foundation

/// A structured event extracted from unstructured input — the text read off a
/// photo/screenshot of an appointment card, ticket, or invite (via OCR), or a
/// typed/spoken line. The user reviews and confirms this before it becomes a
/// `Reminder`, per the approval-first Core Philosophy in README.md.
public struct CapturedEvent: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    /// The resolved date/time of the event, if one could be determined.
    public let date: Date?
    public let location: String?
    public let details: String?
    public let recurrence: RecurrenceRule?
    public let ambiguities: Set<CaptureAmbiguity>
    /// 0…1 estimate of how confident parsing was, surfaced in the review UI.
    public let confidence: Double

    public init(
        id: UUID = UUID(),
        title: String,
        date: Date? = nil,
        location: String? = nil,
        details: String? = nil,
        recurrence: RecurrenceRule? = nil,
        ambiguities: Set<CaptureAmbiguity> = [],
        confidence: Double = 0
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.location = location
        self.details = details
        self.recurrence = recurrence
        self.ambiguities = ambiguities
        self.confidence = min(1, max(0, confidence))
    }

    /// Whether this capture has enough to schedule an alarm without edits.
    public var isSchedulable: Bool {
        date != nil && !title.isEmpty
    }

    /// Turns a confirmed capture into a schedulable `Reminder`. Returns `nil`
    /// when there's no resolved date to fire on.
    public func makeReminder(
        leadTime: TimeInterval = 30 * 60,
        sound: Reminder.AlarmSound = .aurora
    ) -> Reminder? {
        guard let date else { return nil }
        return Reminder(
            title: title,
            notes: details,
            location: location,
            dueDate: date,
            recurrence: recurrence,
            leadTime: leadTime,
            sound: sound,
            sourceAgent: .reminder
        )
    }
}

/// Parsing uncertainty that must be shown before a capture can be committed.
public enum CaptureAmbiguity: String, CaseIterable, Hashable, Sendable {
    case ambiguousNumericDate
    case daylightSavingAdjustment
    case invalidDate
    case missingDate
    case missingTime
    case pastDate

    public var message: String {
        switch self {
        case .ambiguousNumericDate:
            "The numeric date could mean two different days. Choose the intended date."
        case .daylightSavingAdjustment:
            "That local time changes at a daylight-saving boundary. Confirm the adjusted time."
        case .invalidDate:
            "The entered date does not exist. Choose a valid date."
        case .missingDate:
            "A time was found without a date. Choose the intended day."
        case .missingTime:
            "A date was found without a time. Choose the intended time."
        case .pastDate:
            "The parsed date is in the past. Confirm it or choose a future date."
        }
    }
}
