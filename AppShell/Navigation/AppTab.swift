/// The five root-level tabs, per README.md's Product Preview and
/// docs/MASTER_ROADMAP.md Phase 4's Core Product deliverables.
public enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case timeline
    case memory
    case insights
    case settings

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .home: return "Home"
        case .timeline: return "Timeline"
        case .memory: return "Memory"
        case .insights: return "Insights"
        case .settings: return "Settings"
        }
    }

    public var symbolName: String {
        switch self {
        case .home: return "house.fill"
        case .timeline: return "list.bullet.rectangle.fill"
        case .memory: return "brain.head.profile"
        case .insights: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape.fill"
        }
    }
}
