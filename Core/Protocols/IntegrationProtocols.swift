import Foundation

/// Capability states for optional system integrations (#37).
public enum CapabilityState: String, Sendable, Codable, CaseIterable {
    case unavailable
    case notDetermined
    case denied
    case limited
    case authorized
}

/// Calendar read/write surface. Implementations may wrap EventKit.
public protocol CalendarIntegrating: Sendable {
    func authorizationState() async -> CapabilityState
    func fetchEvents(from start: Date, to end: Date) async throws -> [CalendarEvent]
}

/// Reminders surface. Separate from Calendar for least privilege.
public protocol RemindersIntegrating: Sendable {
    func authorizationState() async -> CapabilityState
    func fetchOpenReminders() async throws -> [TaskItem]
}

/// Weather context for briefings and outdoor plans.
public protocol WeatherIntegrating: Sendable {
    func authorizationState() async -> CapabilityState
    func currentWeather() async throws -> WeatherSnapshot
}

/// Travel-time / routing estimates.
public protocol TravelTimeIntegrating: Sendable {
    func authorizationState() async -> CapabilityState
    func travelTimeMinutes(from: String, to: String, departingAt: Date) async throws -> Int
}

/// Cloud sync is optional and never required for local use.
public protocol CloudSyncIntegrating: Sendable {
    func authorizationState() async -> CapabilityState
    func isSyncEnabled() async -> Bool
    func setSyncEnabled(_ enabled: Bool) async throws
}

/// Deterministic doubles for unit tests (#37 / #38).
public struct UnavailableCalendarIntegration: CalendarIntegrating {
    public init() {}

    public func authorizationState() async -> CapabilityState {
        .denied
    }

    public func fetchEvents(from _: Date, to _: Date) async throws -> [CalendarEvent] {
        throw DomainError.unavailable
    }
}

public struct UnavailableRemindersIntegration: RemindersIntegrating {
    public init() {}

    public func authorizationState() async -> CapabilityState {
        .denied
    }

    public func fetchOpenReminders() async throws -> [TaskItem] {
        throw DomainError.unavailable
    }
}

public struct UnavailableWeatherIntegration: WeatherIntegrating {
    public init() {}

    public func authorizationState() async -> CapabilityState {
        .notDetermined
    }

    public func currentWeather() async throws -> WeatherSnapshot {
        throw DomainError.unavailable
    }
}

public struct UnavailableTravelTimeIntegration: TravelTimeIntegrating {
    public init() {}

    public func authorizationState() async -> CapabilityState {
        .notDetermined
    }

    public func travelTimeMinutes(
        from _: String,
        to _: String,
        departingAt _: Date
    ) async throws -> Int {
        throw DomainError.unavailable
    }
}

public struct DisabledCloudSyncIntegration: CloudSyncIntegrating {
    public init() {}

    public func authorizationState() async -> CapabilityState {
        .notDetermined
    }

    public func isSyncEnabled() async -> Bool {
        false
    }

    public func setSyncEnabled(_: Bool) async throws {
        throw DomainError.unavailableNamed("iCloud sync is disabled in this build")
    }
}

/// UserDefaults-backed optional iCloud sync preference (local-first).
public struct OptionalCloudKitSyncIntegration: CloudSyncIntegrating {
    public static let enabledDefaultsKey = "lifepilot.cloudKitSyncEnabled"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func authorizationState() async -> CapabilityState {
        await isSyncEnabled() ? .authorized : .notDetermined
    }

    public func isSyncEnabled() async -> Bool {
        defaults.bool(forKey: Self.enabledDefaultsKey)
    }

    public func setSyncEnabled(_ enabled: Bool) async throws {
        defaults.set(enabled, forKey: Self.enabledDefaultsKey)
    }
}

/// Fixed weather snapshot for previews and deterministic briefing tests.
public struct StaticWeatherIntegration: WeatherIntegrating {
    private let snapshot: WeatherSnapshot

    public init(snapshot: WeatherSnapshot) {
        self.snapshot = snapshot
    }

    public func authorizationState() async -> CapabilityState {
        .authorized
    }

    public func currentWeather() async throws -> WeatherSnapshot {
        snapshot
    }
}

/// Fixed travel ETA for previews and deterministic leave-by tests.
public struct StaticTravelTimeIntegration: TravelTimeIntegrating {
    private let minutes: Int

    public init(minutes: Int) {
        self.minutes = max(1, minutes)
    }

    public func authorizationState() async -> CapabilityState {
        .authorized
    }

    public func travelTimeMinutes(
        from _: String,
        to _: String,
        departingAt _: Date
    ) async throws -> Int {
        minutes
    }
}
