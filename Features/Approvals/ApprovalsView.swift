import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Review queue for exact action proposals — Phase 2 card stack.
public struct ApprovalsView: View {
    @State private var viewModel: ApprovalsViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(viewModel: ApprovalsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if let error = viewModel.lastError {
                    StatusBanner(message: error, style: .risk)
                }

                Text(
                    viewModel.pending.isEmpty
                        ? "No actions waiting for approval."
                        : "\(viewModel.pending.count) actions need your review."
                )
                .font(.LifePilot.body)
                .foregroundStyle(Color.LifePilot.textSecondary)

                if viewModel.pending.isEmpty {
                    EmptyStateView(
                        symbolName: "checkmark.shield",
                        message: "Approved actions will appear in history below."
                    )
                } else {
                    ForEach(viewModel.pending) { proposal in
                        pendingCard(proposal)
                            .lifePilotAnimation(Motion.spring, reduceMotion: reduceMotion, value: proposal.id)
                    }
                }

                if !viewModel.history.isEmpty {
                    SectionHeader(title: "History", symbolName: "clock.arrow.circlepath")
                    ForEach(viewModel.history.prefix(12)) { record in
                        GlowCard {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.state.rawValue.capitalized)
                                    .font(.LifePilot.titleMedium)
                                    .foregroundStyle(Color.LifePilot.textPrimary)
                                if let result = record.executionResult {
                                    Text(result)
                                        .font(.LifePilot.caption)
                                        .foregroundStyle(Color.LifePilot.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .background(AmbientBackground())
        .navigationTitle("Approvals")
        .task { await viewModel.load() }
    }

    private func pendingCard(_ proposal: ActionProposal) -> some View {
        GlowCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(proposal.title)
                    .font(.LifePilot.titleMedium)
                    .foregroundStyle(Color.LifePilot.textPrimary)
                Text(proposal.detail)
                    .font(.LifePilot.body)
                    .foregroundStyle(Color.LifePilot.textSecondary)
                if let evidence = proposal.evidence.first {
                    Text("Evidence: \(evidence.summary)")
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
                HStack(spacing: Spacing.sm) {
                    Button("Approve") {
                        Task { await viewModel.approve(proposal) }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.LifePilot.accentEnd)
                    Button("Decline") {
                        Task { await viewModel.reject(proposal) }
                    }
                    .buttonStyle(.bordered)
                }
                .accessibilityElement(children: .contain)
            }
        }
    }
}
