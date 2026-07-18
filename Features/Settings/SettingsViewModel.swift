import Foundation
import LifePilotCore
import Observation

/// Persisted settings and privacy controls for LifePilot-owned data.
@Observable
@MainActor
public final class SettingsViewModel {
    public private(set) var preferences: UserPreferences
    public private(set) var memoryCount: Int = 0
    public private(set) var exportMessage: String?
    public private(set) var syncMessage: String?
    public private(set) var locationMessage: String?
    public private(set) var cloudSyncEnabled = false
    public private(set) var connections: [ConnectionCapability]

    private let preferenceStore: any PreferenceStore
    private let cloudSync: any CloudSyncIntegrating
    private let locationProvider: any LocationProviding
    private let calendarIntegration: any CalendarIntegrating
    private let remindersIntegration: any RemindersIntegrating

    public init(
        preferenceStore: any PreferenceStore,
        cloudSync: any CloudSyncIntegrating = DisabledCloudSyncIntegration(),
        locationProvider: any LocationProviding = UnavailableLocationProvider(),
        calendarIntegration: any CalendarIntegrating = UnavailableCalendarIntegration(),
        remindersIntegration: any RemindersIntegrating = UnavailableRemindersIntegration()
    ) {
        self.preferenceStore = preferenceStore
        self.cloudSync = cloudSync
        self.locationProvider = locationProvider
        self.calendarIntegration = calendarIntegration
        self.remindersIntegration = remindersIntegration
        preferences = UserPreferences()
        connections = [
            ConnectionCapability(id: "calendar", displayName: "Calendar", state: .notRequested),
            ConnectionCapability(id: "reminders", displayName: "Reminders", state: .notRequested),
            ConnectionCapability(id: "notifications", displayName: "Notifications", state: .notRequested),
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

    public func requestLocation() async {
        let state = await locationProvider.requestAuthorization()
        switch state {
        case .authorized, .limited:
            locationMessage = "Location enabled — weather can refresh on Home."
        case .denied:
            locationMessage = "Location denied in system Settings."
        case .unavailable:
            locationMessage = "Location is unavailable on this device."
        case .notDetermined:
            locationMessage = "Location permission still pending."
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

    private func refreshConnections() async {
        let calendar = await calendarIntegration.authorizationState()
        let reminders = await remindersIntegration.authorizationState()
        let location = await locationProvider.authorizationState()
        let sync = await cloudSync.authorizationState()
        setConnection("calendar", Self.permission(from: calendar))
        setConnection("reminders", Self.permission(from: reminders))
        setConnection("location", Self.permission(from: location))
        setConnection("weather", Self.permission(from: location))
        setConnection("cloudSync", Self.permission(from: sync))
    }

    private func setConnection(_ id: String, _ state: PermissionState) {
        if let index = connections.firstIndex(where: { $0.id == id }) {
            connections[index].state = state
        }
    }

    private static func permission(from state: CapabilityState) -> PermissionState {
        switch state {
        case .authorized: .authorized
        case .limited: .limited
        case .denied: .denied
        case .unavailable: .unavailable
        case .notDetermined: .notRequested
        }
    }
}
