import Foundation

/// A user task or reminder. Distinct from `DaySignal` — a `TaskItem` is
/// something the user owns and can complete directly, not just an observed
/// fact for Ghost Brain to reason over.
public struct TaskItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let dueDate: Date?
    public let isCompleted: Bool
    public let priority: Priority

    public init(
        id: UUID = UUID(),
        title: String,
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        priority: Priority = .normal
    ) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.priority = priority
    }

    public enum Priority: String, Comparable, CaseIterable, Sendable {
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
