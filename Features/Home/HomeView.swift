import LifePilotDesignSystem
import LifePilotGhostBrain
import SwiftUI

/// The Home screen — Phase 3's placeholder-driven precursor to the full
/// Morning Briefing (docs/MASTER_ROADMAP.md Phase 4). Hero header, Ghost
/// Brain recommendations, upcoming schedule, quick actions, and recent
/// activity, all populated from mock data via `HomeViewModel`.
public struct HomeView: View {
    @State private var viewModel: HomeViewModel

    public init(ghostBrain: GhostBrainServing) {
        _viewModel = State(initialValue: HomeViewModel(ghostBrain: ghostBrain))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                heroHeader
                ghostBrainSection
                upcomingScheduleSection
                quickActionsSection
                recentActivitySection
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.LifePilot.backgroundPrimary)
        .task { await viewModel.load() }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(viewModel.dateText.isEmpty ? " " : viewModel.dateText)
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textSecondary)

            Text(viewModel.greeting.isEmpty ? "Good morning" : viewModel.greeting)
                .font(.LifePilot.titleLarge)
                .foregroundStyle(Color.LifePilot.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Ghost Brain

    private var ghostBrainSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Prepared for you", symbolName: "sparkle")

            if viewModel.recommendations.isEmpty {
                EmptyStateView(
                    symbolName: "sparkle",
                    message: "Ghost Brain is preparing your recommendations."
                )
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(Array(viewModel.recommendations.enumerated()), id: \.offset) { _, content in
                        BriefingCard(content: content)
                    }
                }
            }
        }
    }

    // MARK: - Upcoming Schedule

    private var upcomingScheduleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Upcoming Schedule", symbolName: "calendar")

            if viewModel.upcomingEvents.isEmpty {
                EmptyStateView(symbolName: "calendar", message: "Nothing else on your calendar today.")
            } else {
                CardContainer {
                    VStack(spacing: 0) {
                        ForEach(viewModel.upcomingEvents) { event in
                            TimelineRow(content: .init(
                                time: event.startDate.formatted(date: .omitted, time: .shortened),
                                title: event.title,
                                subtitle: event.location
                            ))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Quick Actions", symbolName: "bolt.fill")

            HStack(spacing: Spacing.sm) {
                QuickActionCard(symbolName: "envelope.fill", title: "Inbox")
                QuickActionCard(symbolName: "checklist", title: "Tasks")
                QuickActionCard(symbolName: "airplane", title: "Travel")
            }
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Recent Activity", symbolName: "clock.arrow.circlepath")

            EmptyStateView(
                symbolName: "clock.arrow.circlepath",
                message: "Approved and dismissed actions will appear here."
            )
        }
    }
}

#Preview {
    HomeView(ghostBrain: MockRecommendationProvider())
}
