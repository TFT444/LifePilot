import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Review queue for exact action proposals. Edited parameters require a new approval.
public struct ApprovalsView: View {
    @State private var viewModel: ApprovalsViewModel

    public init(viewModel: ApprovalsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        List {
            if let error = viewModel.lastError {
                Section {
                    Text(error)
                        .foregroundStyle(Color.LifePilot.signalRisk)
                        .font(.LifePilot.caption)
                }
            }

            Section("Pending") {
                if viewModel.pending.isEmpty {
                    Text("No actions waiting for approval.")
                        .foregroundStyle(Color.LifePilot.textSecondary)
                } else {
                    ForEach(viewModel.pending) { proposal in
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(proposal.title)
                                .font(.LifePilot.body)
                                .foregroundStyle(Color.LifePilot.textPrimary)
                            Text(proposal.detail)
                                .font(.LifePilot.caption)
                                .foregroundStyle(Color.LifePilot.textSecondary)
                            if let evidence = proposal.evidence.first {
                                Text("Evidence: \(evidence.summary)")
                                    .font(.LifePilot.caption)
                                    .foregroundStyle(Color.LifePilot.textSecondary)
                            }
                            HStack {
                                Button("Approve") {
                                    Task { await viewModel.approve(proposal) }
                                }
                                .buttonStyle(.borderedProminent)
                                Button("Reject") {
                                    viewModel.reject(proposal)
                                }
                                .buttonStyle(.bordered)
                            }
                            .accessibilityElement(children: .contain)
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                }
            }

            Section("History") {
                ForEach(viewModel.history) { record in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.state.rawValue.capitalized)
                            .font(.LifePilot.body)
                        if let result = record.executionResult {
                            Text(result)
                                .font(.LifePilot.caption)
                                .foregroundStyle(Color.LifePilot.textSecondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Approvals")
    }
}
