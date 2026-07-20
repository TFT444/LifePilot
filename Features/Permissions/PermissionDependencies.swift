import Foundation
import LifePilotCore

#if canImport(UIKit)
import UIKit
#endif

public enum PermissionKind: String, CaseIterable, Sendable {
    case calendar
    case reminders
    case notifications
    case location

    public var displayName: String {
        switch self {
        case .calendar: "Calendar"
        case .reminders: "Reminders"
        case .notifications: "Notifications"
        case .location: "Location"
        }
    }
}

/// Permission adapters shared by onboarding and Settings. Features depend only
/// on Core protocols; AppShell injects the live Services implementations.
public struct PermissionDependencies: Sendable {
    public var calendar: any CalendarIntegrating
    public var reminders: any RemindersIntegrating
    public var notifications: (any NotificationScheduling)?
    public var location: any LocationProviding

    public init(
        calendar: any CalendarIntegrating = UnavailableCalendarIntegration(),
        reminders: any RemindersIntegrating = UnavailableRemindersIntegration(),
        notifications: (any NotificationScheduling)? = nil,
        location: any LocationProviding = UnavailableLocationProvider()
    ) {
        self.calendar = calendar
        self.reminders = reminders
        self.notifications = notifications
        self.location = location
    }

    public func state(for kind: PermissionKind) async -> PermissionState {
        switch kind {
        case .calendar:
            Self.permission(from: await calendar.authorizationState())
        case .reminders:
            Self.permission(from: await reminders.authorizationState())
        case .notifications:
            await notifications?.authorizationState() ?? .unavailable
        case .location:
            Self.permission(from: await location.authorizationState())
        }
    }

    @discardableResult
    public func request(_ kind: PermissionKind) async throws -> PermissionState {
        switch kind {
        case .calendar:
            _ = try await calendar.requestAccess()
        case .reminders:
            _ = try await reminders.requestAccess()
        case .notifications:
            guard let notifications else {
                throw DomainError.unavailableNamed("Notifications are unavailable in this build.")
            }
            _ = try await notifications.requestAuthorization()
        case .location:
            _ = await location.requestAuthorization()
        }
        return await state(for: kind)
    }

    private static func permission(from state: CapabilityState) -> PermissionState {
        switch state {
        case .authorized: .authorized
        case .limited: .limited
        case .denied: .denied
        case .restricted: .restricted
        case .unavailable: .unavailable
        case .notDetermined: .notRequested
        }
    }
}

enum PermissionSystemSettings {
    static var url: URL? {
        #if canImport(UIKit)
        URL(string: UIApplication.openSettingsURLString)
        #else
        URL(string: "x-apple.systempreferences:com.apple.preference.security")
        #endif
    }
}
