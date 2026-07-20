import Foundation
import LifePilotCore
import Observation

/// Persisted settings, permission connections, and privacy controls.
@Observable
@MainActor
public final class SettingsViewModel {
    public private(set) var preferences: UserPreferences
    public private(set) var memoryCount: Int = 0
    public private(set) var exportMessage: String?
    public private(set) var syncMessage: String?
    public private(set) var connectionMessage: String?
    public private(set) var cloudSyncEnabled = false
    public private(set) var connections: [ConnectionCapability]

    private let preferenceStore: any PreferenceStore
    private let cloudSync: any CloudSyncIntegrating
    private let permissions: PermissionDependencies

    public init(
        preferenceStore: any PreferenceStore,
        cloudSync: any CloudSyncIntegrating = DisabledCloudSyncIntegration(),
        permissions: PermissionDependencies = PermissionDependencies()
    ) {
        self.preferenceStore = preferenceStore
        self.cloudSync = cloudSync
        self.permissions = permissions
        preferences = UserPreferences()
        connections = [
            ConnectionCapability(id: "calendar", displayName: "Calendar", state: .notRequested),
            ConnectionCapability(id: "reminders", displayName: "Reminders", state: .notRequested),
            ConnectionCapability(
                id: "notifications",
                displayName: "Notifications",
                state: .notRequested
            ),
            ConnectionCapability(id: "location", displayName: "Location", state: .notRequested),
            ConnectionCapability(id: "weather", displayName: "Weather", state: .notRequested),
            ConnectionCapability(id: "cloudSync", displayName: "Cloud Sync", state: .notRequested),
        ]
    }

    public func load() async {
        preferences = await preferenceStore.loadPreferences()
        memoryCount = await preferenceStore.allMemory().count
        cloudSyncEnabled = await cloudSync.isSyncEnabled()
        await refreshConnections()
    }

    public func setOnboardingCompleted(_ value: Bool) async throws {
        preferences.onboardingCompleted = value
        try await preferenceStore.savePreferences(preferences)
    }

    public func setSensitivePreviews(_ enabled: Bool) async throws {
        preferences.sensitiveNotificationPreviews = enabled
        try await preferenceStore.savePreferences(preferences)
    }

    public func setBriefingHour(_ hour: Int) async throws {
        preferences.briefingHour = min(23, max(0, hour))
        try await preferenceStore.savePreferences(preferences)
    }

    public func setQuietHours(start: Int, end: Int) async throws {
        preferences.quietHoursStart = min(23, max(0, start))
        preferences.quietHoursEnd = min(23, max(0, end))
        try await preferenceStore.savePreferences(preferences)
    }

    public func setAppearance(_ appearance: UserPreferences.AppearancePreference) async throws {
        preferences.appearance = appearance
        try await preferenceStore.savePreferences(preferences)
    }

    public func setCloudSyncEnabled(_ enabled: Bool) async {
        do {
            try await cloudSync.setSyncEnabled(enabled)
            cloudSyncEnabled = await cloudSync.isSyncEnabled()
            syncMessage = enabled
                ? "iCloud sync enabled. Restart the app to attach CloudKit to the store."
                : "iCloud sync off — data stays on this device."
            await load()
        } catch {
            syncMessage = "Could not change iCloud sync."
            cloudSyncEnabled = await cloudSync.isSyncEnabled()
        }
    }

    public func requestConnection(_ kind: PermissionKind) async {
        connectionMessage = nil
        do {
            let state = try await permissions.request(kind)
            connectionMessage = Self.connectionMessage(for: kind, state: state)
        } catch {
            connectionMessage = error.localizedDescription
        }
        await refreshConnections()
    }

    public func exportData() async {
        do {
            let data = try await preferenceStore.exportAll()
            exportMessage = "Exported \(data.count) bytes of LifePilot-owned data."
        } catch {
            exportMessage = "Export failed."
        }
    }

    public func deleteAllData() async {
        do {
            try await preferenceStore.deleteAllLifePilotData()
            preferences = await preferenceStore.loadPreferences()
            memoryCount = 0
            exportMessage = "All LifePilot-owned local data deleted."
        } catch {
            exportMessage = "Delete failed."
        }
    }

    public func refreshConnections() async {
        async let calendar = permissions.state(for: .calendar)
        async let reminders = permissions.state(for: .reminders)
        async let notifications = permissions.state(for: .notifications)
        async let location = permissions.state(for: .location)
        let sync = await cloudSync.authorizationState()
        setConnection("calendar", await calendar)
        setConnection("reminders", await reminders)
        setConnection("notifications", await notifications)
        setConnection("location", await location)
        setConnection("weather", await location)
        setConnection("cloudSync", Self.permission(from: sync))
    }

    public func state(for kind: PermissionKind) -> PermissionState {
        connections.first(where: { $0.id == kind.rawValue })?.state ?? .unavailable
    }

    private func setConnection(_ id: String, _ state: PermissionState) {
        if let index = connections.firstIndex(where: { $0.id == id }) {
            connections[index].state = state
            connections[index].lastCheckedAt = Date()
        }
    }

    private static func connectionMessage(
        for kind: PermissionKind,
        state: PermissionState
    ) -> String {
        switch state {
        case .authorized:
            "\(kind.displayName) connected."
        case .limited:
            "\(kind.displayName) has limited access. Review access in system Settings."
        case .denied:
            "\(kind.displayName) is denied. Open system Settings to change access."
        case .restricted:
            "\(kind.displayName) is restricted by this device or account."
        case .unavailable:
            "\(kind.displayName) is unavailable on this device."
        case .notRequested:
            "\(kind.displayName) permission is still pending."
        }
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
