import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

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
        cloudSync: any CloudSyncIntegrating = DisabledCloudSyncIntegration()
    ) {
        _viewModel = State(
            initialValue: SettingsViewModel(
                preferenceStore: preferenceStore,
                cloudSync: cloudSync
            )
        )
        self.preferenceStore = preferenceStore
        self.actionExecutor = actionExecutor
        self.approvalStore = approvalStore
    }

    public var body: some View {
        List {
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
                Text("Local-first. Enabling prepares CloudKit for LifePilot-owned data; "
                    + "Calendar and Reminders stay on-device sources of truth.")
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
                LabeledContent("Version", value: "0.2.0-daily-life-mvp")
                Text("Daily-life assistant — tasks, schedules, briefing, and approvals. "
                    + "No banking, shopping, or medical features.")
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
                NavigationLink("Memory") {
                    MemoryView(preferenceStore: preferenceStore)
                }
            }
        }
        .navigationTitle("Settings")
        .task { await viewModel.load() }
    }
}
