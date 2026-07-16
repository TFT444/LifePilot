import Foundation
import LifePilotCore
import UserNotifications

/// Real UserNotifications adapter. Respects sensitive-preview preference via
/// callers (body content); schedules are idempotent by identifier.
public struct UserNotificationsScheduler: NotificationScheduling {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func authorizationState() async -> PermissionState {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notRequested
        case .denied: return .denied
        case .authorized, .provisional, .ephemeral: return .authorized
        @unknown default: return .unavailable
        }
    }

    public func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    public func schedule(
        id: String,
        title: String,
        body: String,
        fireDate: Date
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try await center.add(request)
    }

    public func cancel(id: String) async throws {
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }

    public func cancelAll() async throws {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
}
