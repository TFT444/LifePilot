import Foundation

/// Owns the Settings screen's state. Architecture only in this phase —
/// no settings actually persist yet; see docs/MASTER_ROADMAP.md Phase 4
/// for the full Settings deliverable.
@Observable
@MainActor
public final class SettingsViewModel {
    public var sections: [SettingsSection] = SettingsSection.placeholderSections

    public init() {}
}

/// A grouped section of settings rows, e.g. "Account" or "Privacy."
public struct SettingsSection: Identifiable {
    public let id: String
    public let title: String
    public let rows: [SettingsRow]

    public static let placeholderSections: [SettingsSection] = [
        SettingsSection(id: "account", title: "Account", rows: [
            SettingsRow(id: "profile", symbolName: "person.crop.circle.fill", title: "Profile"),
            SettingsRow(id: "connected", symbolName: "link", title: "Connected Apps"),
        ]),
        SettingsSection(id: "privacy", title: "Privacy & Security", rows: [
            SettingsRow(id: "approvals", symbolName: "checkmark.shield.fill", title: "Approval Preferences"),
            SettingsRow(id: "data", symbolName: "lock.fill", title: "Data & Privacy"),
        ]),
        SettingsSection(id: "about", title: "About", rows: [
            SettingsRow(id: "version", symbolName: "info.circle.fill", title: "Version", detail: "0.1.0"),
        ]),
    ]
}

/// A single row within a `SettingsSection`.
public struct SettingsRow: Identifiable {
    public let id: String
    public let symbolName: String
    public let title: String
    public let detail: String?

    public init(id: String, symbolName: String, title: String, detail: String? = nil) {
        self.id = id
        self.symbolName = symbolName
        self.title = title
        self.detail = detail
    }
}
