import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Wiring bag so SettingsView stays under SwiftLint parameter limits.
public struct SettingsConnections: Sendable {
    public var cloudSync: any CloudSyncIntegrating
    public var permissions: PermissionDependencies

    public init(
        cloudSync: any CloudSyncIntegrating = DisabledCloudSyncIntegration(),
        permissions: PermissionDependencies = PermissionDependencies()
    ) {
        self.cloudSync = cloudSync
        self.permissions = permissions
    }
}

/// Privacy, connections, briefing time, export, deletion, and approvals.
public struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @State private var confirmDelete = false
    @State private var transitStopID = ""
    @State private var transitStopName = ""
    @State private var transitLines = ""
    @Environment(\.scenePhase) private var scenePhase
    private let preferenceStore: any PreferenceStore
    private let actionExecutor: any ActionExecuting
    private let approvalStore: any ApprovalStore
    private let onPermissionsChanged: () -> Void

    public init(
        preferenceStore: any PreferenceStore,
        actionExecutor: any ActionExecuting,
        approvalStore: any ApprovalStore,
        connections: SettingsConnections = SettingsConnections(),
        onPermissionsChanged: @escaping () -> Void = {}
    ) {
        _viewModel = State(
            initialValue: SettingsViewModel(
                preferenceStore: preferenceStore,
                cloudSync: connections.cloudSync,
                permissions: connections.permissions
            )
        )
        self.preferenceStore = preferenceStore
        self.actionExecutor = actionExecutor
        self.approvalStore = approvalStore
        self.onPermissionsChanged = onPermissionsChanged
    }

    public var body: some View {
        List {
            Section {
                HStack(spacing: Spacing.md) {
                    BrandMark(size: 58)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LifePilot")
                            .font(.LifePilot.titleMedium)
                        Text("Local-first daily planning")
                            .font(.LifePilot.caption)
                            .foregroundStyle(Color.LifePilot.textSecondary)
                    }
                }
                .padding(.vertical, Spacing.sm)
                .accessibilityElement(children: .combine)
            }

            Section("Briefing") {
                Stepper(
                    "Briefing hour: \(viewModel.preferences.briefingHour):00",
                    value: Binding(
                        get: { viewModel.preferences.briefingHour },
                        set: { newValue in
                            Task { try? await viewModel.setBriefingHour(newValue) }
                        }
                    ),
                    in: 5 ... 11
                )
                Stepper(
                    "Quiet hours start: \(viewModel.preferences.quietHoursStart ?? 22):00",
                    value: Binding(
                        get: { viewModel.preferences.quietHoursStart ?? 22 },
                        set: { newValue in
                            Task {
                                try? await viewModel.setQuietHours(
                                    start: newValue,
                                    end: viewModel.preferences.quietHoursEnd ?? 7
                                )
                            }
                        }
                    ),
                    in: 0 ... 23
                )
                Stepper(
                    "Quiet hours end: \(viewModel.preferences.quietHoursEnd ?? 7):00",
                    value: Binding(
                        get: { viewModel.preferences.quietHoursEnd ?? 7 },
                        set: { newValue in
                            Task {
                                try? await viewModel.setQuietHours(
                                    start: viewModel.preferences.quietHoursStart ?? 22,
                                    end: newValue
                                )
                            }
                        }
                    ),
                    in: 0 ... 23
                )
            }

            Section("Actions") {
                NavigationLink("Approvals") {
                    ApprovalsView(
                        viewModel: ApprovalsViewModel(
                            executor: actionExecutor,
                            approvalStore: approvalStore
                        )
                    )
                }
            }

            TransitSettingsSection(
                stopID: $transitStopID,
                stopName: $transitStopName,
                lines: $transitLines,
                message: viewModel.transitMessage,
                onSave: {
                    Task {
                        await viewModel.setTransitConfiguration(
                            stopID: transitStopID,
                            stopName: transitStopName,
                            linesText: transitLines
                        )
                    }
                }
            )

            Section("Sync") {
                Toggle(
                    "iCloud sync (optional)",
                    isOn: Binding(
                        get: { viewModel.cloudSyncEnabled },
                        set: { newValue in
                            Task { await viewModel.setCloudSyncEnabled(newValue) }
                        }
                    )
                )
                Text("Local-first. Enabling prepares CloudKit for LifePilot-owned data.")
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
                if let syncMessage = viewModel.syncMessage {
                    Text(syncMessage)
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
            }

            Section("Connections") {
                ForEach(viewModel.connections) { connection in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ConnectionStatusRow(
                            title: connection.displayName,
                            state: connection.state,
                            detail: connection.lastCheckedAt.map {
                                "Checked \($0.formatted(date: .omitted, time: .shortened))"
                            }
                        )
                        PermissionConnectionAction(connection: connection) { kind in
                            Task {
                                await viewModel.requestConnection(kind)
                                onPermissionsChanged()
                            }
                        }
                    }
                }
                if let connectionMessage = viewModel.connectionMessage {
                    Text(connectionMessage)
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
            }

            Section("Privacy") {
                Toggle(
                    "Show sensitive details in notifications",
                    isOn: Binding(
                        get: { viewModel.preferences.sensitiveNotificationPreviews },
                        set: { newValue in
                            Task { try? await viewModel.setSensitivePreviews(newValue) }
                        }
                    )
                )
                Text("Off by default — private details stay out of notification previews.")
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
                NavigationLink("Privacy & data flow") {
                    PrivacyAndDataView()
                }
            }

            Section("Appearance") {
                Picker(
                    "Theme",
                    selection: Binding(
                        get: { viewModel.preferences.appearance },
                        set: { value in
                            Task { try? await viewModel.setAppearance(value) }
                        }
                    )
                ) {
                    ForEach(UserPreferences.AppearancePreference.allCases, id: \.self) { appearance in
                        Text(appearance.rawValue.capitalized).tag(appearance)
                    }
                }
                Text("LifePilot also respects Reduce Motion, Reduce Transparency, "
                    + "Increase Contrast, and Dynamic Type.")
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }

            Section("Your data") {
                Text("Memory items: \(viewModel.memoryCount)")
                    .font(.LifePilot.caption)
                Button("Export LifePilot data") {
                    Task { await viewModel.exportData() }
                }
                Button("Delete all LifePilot data", role: .destructive) {
                    confirmDelete = true
                }
                if let message = viewModel.exportMessage {
                    Text(message)
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
            }

            Section("About") {
                LabeledContent("Version", value: "0.3.0-ship-candidate")
                Text("Daily-life assistant — tasks, schedules, briefing, and approvals. "
                    + "No banking, shopping, or medical features.")
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
                NavigationLink("Memory") {
                    MemoryView(preferenceStore: preferenceStore)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AmbientBackground())
        .navigationTitle("Settings")
        .task {
            await viewModel.load()
            transitStopID = viewModel.preferences.transitStopID
            transitStopName = viewModel.preferences.transitStopName
            transitLines = viewModel.preferences.transitLineNames.joined(separator: ", ")
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await viewModel.refreshConnections()
                onPermissionsChanged()
            }
        }
        .confirmationDialog(
            "Delete all LifePilot-owned local data?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete all local data", role: .destructive) {
                Task { await viewModel.deleteAllData() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes tasks, preferences, Memory, approvals, and audit records "
                + "owned by LifePilot. Apple Calendar and Reminders remain unchanged.")
        }
    }

}

private struct PermissionConnectionAction: View {
    @Environment(\.openURL) private var openURL
    let connection: ConnectionCapability
    let onRequest: (PermissionKind) -> Void

    @ViewBuilder
    var body: some View {
        if let kind = PermissionKind(rawValue: connection.id) {
            switch connection.state {
            case .notRequested:
                Button("Connect \(kind.displayName)") {
                    onRequest(kind)
                }
            case .denied, .limited:
                Button("Open System Settings") {
                    if let url = PermissionSystemSettings.url {
                        openURL(url)
                    }
                }
            case .authorized, .restricted, .unavailable:
                EmptyView()
            }
        }
    }
}

private struct TransitSettingsSection: View {
    @Binding var stopID: String
    @Binding var stopName: String
    @Binding var lines: String
    let message: String?
    let onSave: () -> Void

    var body: some View {
        Section("Live transit") {
            TextField("Stop ID (for example 940GZZLUOXC)", text: $stopID)
                .accessibilityLabel("Transit stop identifier")
            TextField("Stop name (optional)", text: $stopName)
                .accessibilityLabel("Transit stop name")
            TextField("Lines, separated by commas (optional)", text: $lines)
                .accessibilityLabel("Relevant transit lines")
            Button("Save transit stop", action: onSave)
            Text("Uses TfL's public-data path with no client API secret. "
                + "Leave the stop ID blank to disable live transit.")
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textSecondary)
            if let message {
                Text(message)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }
        }
    }
}

public struct PrivacyAndDataView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                InsightHero(
                    title: "Private by default",
                    detail: "Core planning works locally and without an account."
                )
                privacyCard(
                    "On this device",
                    "Tasks, preferences, Memory, approvals, and audit records stay local "
                        + "unless you opt into iCloud sync.",
                    "iphone"
                )
                privacyCard(
                    "Permission by permission",
                    "Calendar, Reminders, Notifications, and Location remain optional. "
                        + "Declining one does not block local planning.",
                    "hand.raised.fill"
                )
                privacyCard(
                    "No hidden automation",
                    "External writes require an exact proposal and explicit approval.",
                    "checkmark.shield.fill"
                )
                StatusBanner(
                    message: "The repository privacy notice is a draft and must receive "
                        + "legal review before App Store publication.",
                    style: .warning
                )
            }
            .padding(Spacing.lg)
        }
        .background(AmbientBackground())
        .navigationTitle("Privacy & Data")
    }

    private func privacyCard(_ title: String, _ detail: String, _ symbol: String) -> some View {
        GlowCard {
            Label {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.LifePilot.titleMedium)
                    Text(detail)
                        .font(.LifePilot.body)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
            } icon: {
                Image(systemName: symbol)
                    .foregroundStyle(Color.LifePilot.accentTeal)
            }
        }
    }
}
