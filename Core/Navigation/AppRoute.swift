import Foundation

/// Typed routes for notifications, capture, and internal navigation (#36).
public enum AppRoute: Hashable, Sendable, Codable {
    case home
    case timeline
    case tasks(filter: TasksFilter?)
    case task(UUID)
    case event(UUID)
    case approvals
    case approval(UUID)
    case memory
    case insights
    case settings
    case briefing
    case quickCapture(QuickCaptureKind)

    public enum TasksFilter: String, Hashable, Sendable, Codable {
        case inbox
        case today
        case upcoming
        case completed
    }

    public enum QuickCaptureKind: String, Hashable, Sendable, Codable {
        case task
        case reminder
        case event
    }

    /// Parses a limited deep-link path such as `lifepilot://tasks/today`.
    public static func resolve(pathComponents: [String]) -> AppRoute? {
        guard let first = pathComponents.first?.lowercased() else { return nil }
        switch first {
        case "home", "":
            return .home
        case "timeline":
            return .timeline
        case "tasks":
            if pathComponents.count > 1,
               let filter = TasksFilter(rawValue: pathComponents[1].lowercased())
            {
                return .tasks(filter: filter)
            }
            if pathComponents.count > 1, let id = UUID(uuidString: pathComponents[1]) {
                return .task(id)
            }
            return .tasks(filter: nil)
        case "events":
            guard pathComponents.count > 1, let id = UUID(uuidString: pathComponents[1]) else {
                return nil
            }
            return .event(id)
        case "approvals":
            if pathComponents.count > 1, let id = UUID(uuidString: pathComponents[1]) {
                return .approval(id)
            }
            return .approvals
        case "memory":
            return .memory
        case "insights":
            return .insights
        case "settings":
            return .settings
        case "briefing":
            return .briefing
        case "capture":
            let kind = pathComponents.count > 1
                ? QuickCaptureKind(rawValue: pathComponents[1].lowercased()) ?? .task
                : .task
            return .quickCapture(kind)
        default:
            return nil
        }
    }
}

/// Resolves routes against current store contents; missing targets fail soft.
public struct AppRouter: Sendable {
    public init() {}

    public func resolveTarget(
        _ route: AppRoute,
        tasks: [TaskItem],
        events: [CalendarEvent]
    ) -> RouteResolution {
        switch route {
        case let .task(id):
            if tasks.contains(where: { $0.id == id }) {
                return .ok(route)
            }
            return .missing("Task not found")
        case let .event(id):
            if events.contains(where: { $0.id == id }) {
                return .ok(route)
            }
            return .missing("Event not found")
        default:
            return .ok(route)
        }
    }

    public enum RouteResolution: Equatable, Sendable {
        case ok(AppRoute)
        case missing(String)
    }
}
