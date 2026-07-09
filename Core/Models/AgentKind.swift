/// Identifies which agent produced a given signal, prediction, or
/// recommendation. See the AI Agent System in README.md for what each
/// agent is responsible for at the product level.
public enum AgentKind: String, CaseIterable, Hashable, Sendable {
    case calendar
    case email
    case travel
    case finance
    case memory
    case reminder
    case shopping
    case health
    case security

    /// A short, display-ready name for the agent, used wherever the UI
    /// attributes a recommendation to its source per docs/MASTER_ROADMAP.md's
    /// Phase 6 UX requirement that agent output be attributable.
    public var displayName: String {
        switch self {
        case .calendar: "Calendar"
        case .email: "Email"
        case .travel: "Travel"
        case .finance: "Finance"
        case .memory: "Memory"
        case .reminder: "Reminder"
        case .shopping: "Shopping"
        case .health: "Health"
        case .security: "Security"
        }
    }

    /// The SF Symbol used to represent this agent throughout the UI.
    public var symbolName: String {
        switch self {
        case .calendar: "calendar"
        case .email: "envelope.fill"
        case .travel: "airplane"
        case .finance: "dollarsign.circle.fill"
        case .memory: "brain.head.profile"
        case .reminder: "bell.fill"
        case .shopping: "cart.fill"
        case .health: "heart.fill"
        case .security: "shield.fill"
        }
    }
}
