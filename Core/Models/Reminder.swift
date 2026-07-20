import Foundation

/// A time-based reminder the Reminder Agent schedules and the app rings like
/// an alarm. This is the Domain-layer shape the app reasons over and persists;
/// platform scheduling (UNUserNotificationCenter) is a Services-layer adapter
/// that consumes these, per docs/ARCHITECTURE.md's Dependency Rules.
public struct Reminder: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let notes: String?
    public let location: String?
    /// When the underlying event happens (e.g. the appointment time).
    public let dueDate: Date
    /// How far ahead of `dueDate` the first alert should fire.
    public let leadTime: TimeInterval
    /// Whether this reminder rings with a full-screen, must-dismiss alarm
    /// rather than a passive banner.
    public let isAlarm: Bool
    public let sound: AlarmSound
    public let sourceAgent: AgentKind
    public var isCompleted: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        location: String? = nil,
        dueDate: Date,
        leadTime: TimeInterval = 30 * 60,
        isAlarm: Bool = true,
        sound: AlarmSound = .aurora,
        sourceAgent: AgentKind = .reminder,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.location = location
        self.dueDate = dueDate
        self.leadTime = max(0, leadTime)
        self.isAlarm = isAlarm
        self.sound = sound
        self.sourceAgent = sourceAgent
        self.isCompleted = isCompleted
    }

    /// The moment the first alert should fire (`dueDate` minus `leadTime`).
    public var fireDate: Date {
        dueDate.addingTimeInterval(-leadTime)
    }

    /// Whether the alert should have fired by `date` (and isn't completed).
    public func isDue(at date: Date) -> Bool {
        !isCompleted && date >= fireDate
    }

    /// Seconds from `date` until the event itself; never negative.
    public func timeUntilDue(from date: Date) -> TimeInterval {
        max(0, dueDate.timeIntervalSince(date))
    }

    /// A curated set of gentle, non-jarring alarm tones. Raw values map to
    /// bundled sound assets / synthesised tones in the Services layer.
    public enum AlarmSound: String, CaseIterable, Sendable {
        case aurora
        case marimba
        case zen

        public var displayName: String {
            switch self {
            case .aurora: "Aurora"
            case .marimba: "Marimba"
            case .zen: "Zen Bells"
            }
        }
    }
}
