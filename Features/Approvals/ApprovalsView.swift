import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Review queue for exact action proposals — Phase 2 card stack.
public struct ApprovalsView: View {
    @State private var viewModel: ApprovalsViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedProposal: ActionProposal?
    @State private var decisionMessage: String?

    public init(viewModel: ApprovalsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if let error = viewModel.lastError {
                    StatusBanner(message: error, style: .risk)
                }
                if let decisionMessage {
                    StatusBanner(message: decisionMessage, style: .info)
                        .accessibilityLabel(decisionMessage)
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
        .sheet(item: $selectedProposal) { proposal in
            proposalReview(proposal)
                .presentationDetents([.medium, .large])
        }
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
                    Button("Review exact change") {
                        selectedProposal = proposal
                    }
                    .buttonStyle(.lifePilotPrimary)
                    Button("Decline") {
                        Task {
                            await viewModel.reject(proposal)
                            decisionMessage = "Declined. Nothing was changed."
                        }
                    }
                    .buttonStyle(.lifePilotSecondary)
                }
                .accessibilityElement(children: .contain)
            }
        }
    }

    private func proposalReview(_ proposal: ActionProposal) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    StatusBanner(
                        message: "Approval applies only to the exact values shown below.",
                        style: .warning
                    )
                    PreparationCard(
                        eyebrow: proposal.actionType.rawValue,
                        title: proposal.title,
                        detail: proposal.detail,
                        symbolName: "checkmark.shield"
                    )
                    SectionHeader(title: "Exact change", symbolName: "arrow.left.arrow.right")
                    proposalParameters(proposal)
                    if let evidence = proposal.evidence.first {
                        Label(evidence.summary, systemImage: "doc.text.magnifyingglass")
                            .font(.LifePilot.caption)
                            .foregroundStyle(Color.LifePilot.textSecondary)
                    }
                    proposalActions(proposal)
                }
                .padding(Spacing.lg)
            }
            .background(AmbientBackground())
            .navigationTitle("Review Proposal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { selectedProposal = nil }
                }
            }
        }
    }

    private func proposalParameters(_ proposal: ActionProposal) -> some View {
        GlowCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(proposal.parameters.keys.sorted(), id: \.self) { key in
                    HStack(alignment: .top) {
                        Text(key.capitalized)
                            .font(.LifePilot.caption)
                            .foregroundStyle(Color.LifePilot.textSecondary)
                        Spacer()
                        Text(proposal.parameters[key] ?? "")
                            .font(.LifePilot.body)
                            .foregroundStyle(Color.LifePilot.textPrimary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
    }

    private func proposalActions(_ proposal: ActionProposal) -> some View {
        VStack(spacing: Spacing.sm) {
            Button("Approve and execute") {
                selectedProposal = nil
                Task {
                    await viewModel.approve(proposal)
                    decisionMessage = viewModel.lastError == nil
                        ? "Approved and execution confirmed."
                        : "Approved, but execution needs attention."
                }
            }
            .buttonStyle(.lifePilotPrimary)
            Button("Decline — make no change") {
                selectedProposal = nil
                Task {
                    await viewModel.reject(proposal)
                    decisionMessage = "Declined. Nothing was changed."
                }
            }
            .buttonStyle(.lifePilotSecondary)
        }
    }
}
