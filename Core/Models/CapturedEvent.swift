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
    /// 0…1 estimate of how confident parsing was, surfaced in the review UI.
    public let confidence: Double

    public init(
        id: UUID = UUID(),
        title: String,
        date: Date? = nil,
        location: String? = nil,
        details: String? = nil,
        confidence: Double = 0
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.location = location
        self.details = details
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
            leadTime: leadTime,
            sound: sound,
            sourceAgent: .reminder
        )
    }
}
