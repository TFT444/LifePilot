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
    case search
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

    private static let simpleRoutes: [String: AppRoute] = [
        "home": .home,
        "": .home,
        "timeline": .timeline,
        "memory": .memory,
        "insights": .insights,
        "settings": .settings,
        "search": .search,
        "briefing": .briefing,
    ]

    /// Parses a limited deep-link path such as `lifepilot://tasks/today`.
    public static func resolve(pathComponents: [String]) -> AppRoute? {
        guard let first = pathComponents.first?.lowercased() else { return nil }
        if let simple = simpleRoutes[first] {
            return simple
        }
        switch first {
        case "tasks":
            return resolveTasks(pathComponents)
        case "events":
            return resolveEvent(pathComponents)
        case "approvals":
            return resolveApprovals(pathComponents)
        case "capture":
            return resolveCapture(pathComponents)
        default:
            return nil
        }
    }

    private static func resolveTasks(_ pathComponents: [String]) -> AppRoute {
        guard pathComponents.count > 1 else { return .tasks(filter: nil) }
        let token = pathComponents[1].lowercased()
        if let filter = TasksFilter(rawValue: token) {
            return .tasks(filter: filter)
        }
        if let id = UUID(uuidString: pathComponents[1]) {
            return .task(id)
        }
        return .tasks(filter: nil)
    }

    private static func resolveEvent(_ pathComponents: [String]) -> AppRoute? {
        guard pathComponents.count > 1, let id = UUID(uuidString: pathComponents[1]) else {
            return nil
        }
        return .event(id)
    }

    private static func resolveApprovals(_ pathComponents: [String]) -> AppRoute {
        if pathComponents.count > 1, let id = UUID(uuidString: pathComponents[1]) {
            return .approval(id)
        }
        return .approvals
    }

    private static func resolveCapture(_ pathComponents: [String]) -> AppRoute {
        let kind = pathComponents.count > 1
            ? QuickCaptureKind(rawValue: pathComponents[1].lowercased()) ?? .task
            : .task
        return .quickCapture(kind)
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
