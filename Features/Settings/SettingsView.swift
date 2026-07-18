import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Wiring bag so SettingsView stays under SwiftLint parameter limits.
public struct SettingsConnections: Sendable {
    public var cloudSync: any CloudSyncIntegrating
    public var locationProvider: any LocationProviding
    public var calendarIntegration: any CalendarIntegrating
    public var remindersIntegration: any RemindersIntegrating

    public init(
        cloudSync: any CloudSyncIntegrating = DisabledCloudSyncIntegration(),
        locationProvider: any LocationProviding = UnavailableLocationProvider(),
        calendarIntegration: any CalendarIntegrating = UnavailableCalendarIntegration(),
        remindersIntegration: any RemindersIntegrating = UnavailableRemindersIntegration()
    ) {
        self.cloudSync = cloudSync
        self.locationProvider = locationProvider
        self.calendarIntegration = calendarIntegration
        self.remindersIntegration = remindersIntegration
    }
}

/// Privacy, connections, briefing time, export, deletion, and approvals.
public struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    private let preferenceStore: any PreferenceStore
    private let actionExecutor: any ActionExecuting
    private let approvalStore: any ApprovalStore

    public init(
        preferenceStore: any PreferenceStore,
        actionExecutor: any ActionExecuting,
        approvalStore: any ApprovalStore,
        connections: SettingsConnections = SettingsConnections()
    ) {
        _viewModel = State(
            initialValue: SettingsViewModel(
                preferenceStore: preferenceStore,
                cloudSync: connections.cloudSync,
                locationProvider: connections.locationProvider,
                calendarIntegration: connections.calendarIntegration,
                remindersIntegration: connections.remindersIntegration
            )
        )
        self.preferenceStore = preferenceStore
        self.actionExecutor = actionExecutor
        self.approvalStore = approvalStore
    }

    public var body: some View {
        List {
            Section {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.LifePilot.accent)
                            .frame(width: 56, height: 56)
                        Text("LP")
                            .font(.LifePilot.titleMedium)
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LifePilot")
                            .font(.LifePilot.titleMedium)
                        Text("Daily-life assistant · on-device first")
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
                    HStack {
                        Text(connection.displayName)
                        Spacer()
                        Text(connection.state.rawValue)
                            .font(.LifePilot.caption)
                            .foregroundStyle(Color.LifePilot.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                }
                Button("Enable Location for weather") {
                    Task { await viewModel.requestLocation() }
                }
                if let locationMessage = viewModel.locationMessage {
                    Text(locationMessage)
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
            }

            Section("Your data") {
                Text("Memory items: \(viewModel.memoryCount)")
                    .font(.LifePilot.caption)
                Button("Export LifePilot data") {
                    Task { await viewModel.exportData() }
                }
                Button("Delete all LifePilot data", role: .destructive) {
                    Task { await viewModel.deleteAllData() }
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
        .background(Color.LifePilot.backgroundPrimary)
        .navigationTitle("Settings")
        .task { await viewModel.load() }
    }
}
