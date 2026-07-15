import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Privacy, connections, briefing time, export, deletion, and approvals.
public struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    private let actionExecutor: any ActionExecuting

    public init(preferenceStore: any PreferenceStore, actionExecutor: any ActionExecuting) {
        _viewModel = State(initialValue: SettingsViewModel(preferenceStore: preferenceStore))
        self.actionExecutor = actionExecutor
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
                            seed: ApprovalsViewModel.sampleProposals()
                        )
                    )
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
                Text("Finance, shopping, and HealthKit medical features are out of scope.")
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }
        }
        .navigationTitle("Settings")
        .task { await viewModel.load() }
    }
}
