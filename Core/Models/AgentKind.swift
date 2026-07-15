/// Identifies which capability produced a signal, prediction, or
/// recommendation. Daily-life MVP scope only — no finance, shopping, or health.
public enum AgentKind: String, CaseIterable, Hashable, Sendable, Codable {
    case calendar
    case reminder
    case task
    case travel
    case weather
    case memory
    case planning
    case security

    /// Display-ready name for attribution in the UI.
    public var displayName: String {
        switch self {
        case .calendar: "Calendar"
        case .reminder: "Reminder"
        case .task: "Tasks"
        case .travel: "Travel"
        case .weather: "Weather"
        case .memory: "Memory"
        case .planning: "Planning"
        case .security: "Security"
        }
    }

    /// SF Symbol used to represent this source throughout the UI.
    public var symbolName: String {
        switch self {
        case .calendar: "calendar"
        case .reminder: "bell.fill"
        case .task: "checkmark.circle.fill"
        case .travel: "airplane"
        case .weather: "cloud.sun.fill"
        case .memory: "brain.head.profile"
        case .planning: "lightbulb.fill"
        case .security: "shield.fill"
        }
    }
}
