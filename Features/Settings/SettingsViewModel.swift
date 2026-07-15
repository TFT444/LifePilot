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
    public private(set) var connections: [ConnectionCapability]

    private let preferenceStore: any PreferenceStore

    public init(preferenceStore: any PreferenceStore) {
        self.preferenceStore = preferenceStore
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
}
