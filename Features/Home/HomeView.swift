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
                EmptyStatePlaceholder(
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
                EmptyStatePlaceholder(symbolName: "calendar", message: "Nothing else on your calendar today.")
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
                QuickActionButton(symbolName: "envelope.fill", title: "Inbox")
                QuickActionButton(symbolName: "checklist", title: "Tasks")
                QuickActionButton(symbolName: "airplane", title: "Travel")
            }
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Recent Activity", symbolName: "clock.arrow.circlepath")

            EmptyStatePlaceholder(
                symbolName: "clock.arrow.circlepath",
                message: "Approved and dismissed actions will appear here."
            )
        }
    }
}

// MARK: - Local Components

private struct SectionHeader: View {
    let title: String
    let symbolName: String

    var body: some View {
        Label(title, systemImage: symbolName)
            .font(.LifePilot.titleMedium)
            .foregroundStyle(Color.LifePilot.textPrimary)
    }
}

private struct EmptyStatePlaceholder: View {
    let symbolName: String
    let message: String

    var body: some View {
        CardContainer {
            VStack(spacing: Spacing.sm) {
                Image(systemName: symbolName)
                    .font(.system(size: IconSize.md))
                    .foregroundStyle(Color.LifePilot.textSecondary)

                Text(message)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
        }
    }
}

private struct QuickActionButton: View {
    let symbolName: String
    let title: String

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: symbolName)
                .font(.system(size: IconSize.sm, weight: .medium))
                .foregroundStyle(LinearGradient.LifePilot.accent)

            Text(title)
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(Color.LifePilot.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    HomeView(ghostBrain: MockRecommendationProvider())
}
