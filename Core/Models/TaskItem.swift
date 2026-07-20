import Foundation

/// A user-owned task. LifePilot persists these offline; linked reminder
/// notifications are scheduled through a protocol adapter.
public struct TaskItem: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var title: String
    public var notes: String?
    public var dueDate: Date?
    public var startDate: Date?
    public var isCompleted: Bool
    public var completedAt: Date?
    public var priority: Priority
    public var tags: [String]
    public var listID: UUID?
    public var parentID: UUID?
    public var estimatedDuration: TimeInterval?
    public var context: LifeContext
    public var recurrence: RecurrenceRule?
    public var source: DataSource
    public var externalIdentifier: String?
    public var syncState: SyncState
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        startDate: Date? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        priority: Priority = .normal,
        tags: [String] = [],
        listID: UUID? = nil,
        parentID: UUID? = nil,
        estimatedDuration: TimeInterval? = nil,
        context: LifeContext = .personal,
        recurrence: RecurrenceRule? = nil,
        source: DataSource = .local,
        externalIdentifier: String? = nil,
        syncState: SyncState = .localOnly,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.startDate = startDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.priority = priority
        self.tags = tags
        self.listID = listID
        self.parentID = parentID
        self.estimatedDuration = estimatedDuration
        self.context = context
        self.recurrence = recurrence
        self.source = source
        self.externalIdentifier = externalIdentifier
        self.syncState = syncState
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public enum Priority: String, Comparable, CaseIterable, Sendable, Codable {
        case low
        case normal
        case high

        private var sortOrder: Int {
            switch self {
            case .low: return 0
            case .normal: return 1
            case .high: return 2
            }
        }

        public static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.sortOrder < rhs.sortOrder
        }
    }
}

/// A named list containing tasks (Inbox, custom lists, etc.).
public struct TaskList: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var name: String
    public var symbolName: String
    public var isSystem: Bool
    public var sortOrder: Int

    public init(
        id: UUID = UUID(),
        name: String,
        symbolName: String = "list.bullet",
        isSystem: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.isSystem = isSystem
        self.sortOrder = sortOrder
    }

    public static let inboxID =
        UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()

    public static let inbox = TaskList(
        id: inboxID,
        name: "Inbox",
        symbolName: "tray.fill",
        isSystem: true,
        sortOrder: 0
    )
}

/// Simple recurrence for tasks and reminders. Occurrence exceptions live separately.
public struct RecurrenceRule: Hashable, Sendable, Codable {
    public var frequency: Frequency
    public var interval: Int
    public var daysOfWeek: [Int]
    public var endDate: Date?

    public init(
        frequency: Frequency,
        interval: Int = 1,
        daysOfWeek: [Int] = [],
        endDate: Date? = nil
    ) {
        self.frequency = frequency
        self.interval = max(1, interval)
        self.daysOfWeek = daysOfWeek
        self.endDate = endDate
    }

    public enum Frequency: String, Sendable, Codable, CaseIterable {
        case daily
        case weekly
        case monthly
        case yearly
    }
}
