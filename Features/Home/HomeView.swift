import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Editorial Morning Briefing: now → prepare → decide → review.
public struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public init(
        taskStore: any TaskStore,
        eventStore: any EventStore,
        preferenceStore: any PreferenceStore,
        planningEngine: any PlanningEngine = DeterministicPlanningEngine(),
        integrations: HomeBriefingIntegrations = HomeBriefingIntegrations()
    ) {
        _viewModel = State(
            initialValue: HomeViewModel(
                taskStore: taskStore,
                eventStore: eventStore,
                preferenceStore: preferenceStore,
                planningEngine: planningEngine,
                integrations: integrations
            )
        )
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                if let banner = viewModel.statusBanner {
                    StatusBanner(
                        message: banner.message,
                        style: banner.style,
                        actionTitle: "Refresh",
                        action: { Task { await viewModel.refresh() } }
                    )
                    .lifePilotAnimation(Motion.standard, reduceMotion: reduceMotion, value: banner.message)
                }

                heroHeader
                    .lifePilotDepthEntrance()
                ContextRibbon(
                    weather: viewModel.weatherSummary,
                    leaveBy: viewModel.leaveBySummary,
                    freshness: viewModel.lastUpdated == nil ? "Local" : "Updated"
                )
                primaryPreparation
                    .lifePilotDepthEntrance(delay: 0.08)
                transitSection
                prioritiesSection
                upcomingScheduleSection
                preparedSection
                freshnessFooter
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(AmbientBackground())
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.load() }
    }

    private var heroHeader: some View {
        HeroCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(viewModel.dateText.isEmpty ? " " : viewModel.dateText)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)

                Text(viewModel.greeting.isEmpty ? "Good morning" : viewModel.greeting)
                    .font(.LifePilot.titleLarge)
                    .foregroundStyle(Color.LifePilot.textPrimary)
                    .lifePilotAnimation(Motion.spring, reduceMotion: reduceMotion, value: viewModel.greeting)

                Text(orientationLine)
                    .font(.LifePilot.body)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var primaryPreparation: some View {
        if viewModel.isLoading, viewModel.lastUpdated == nil {
            LoadingCardSkeleton()
        } else if let recommendation = viewModel.recommendations.first {
            PreparationCard(
                eyebrow: recommendation.sourceAgent.displayName,
                title: recommendation.title,
                detail: recommendation.reasoning,
                symbolName: recommendation.sourceAgent.symbolName
            )
            .lifePilotAnimation(
                Motion.spring,
                reduceMotion: reduceMotion,
                value: recommendation.title
            )
        } else if let next = viewModel.upcomingEvents.first {
            PreparationCard(
                eyebrow: "Next transition",
                title: next.title,
                detail: next.startDate.formatted(date: .omitted, time: .shortened)
                    + (next.location.map { " · \($0)" } ?? ""),
                symbolName: "calendar.badge.clock"
            )
        } else {
            PreparationCard(
                eyebrow: "Clear space",
                title: "Nothing urgent needs your attention",
                detail: "Add what matters today, or enjoy the breathing room.",
                symbolName: "sparkles"
            )
        }
    }

    private var prioritiesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Top priorities", symbolName: "checkmark.circle")

            if viewModel.topTasks.isEmpty {
                EmptyStateView(
                    symbolName: "checkmark.circle",
                    message: "No open tasks — capture something when you’re ready."
                )
            } else {
                GlowCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ForEach(Array(viewModel.topTasks.prefix(3))) { task in
                            HStack {
                                Text(task.title)
                                    .font(.LifePilot.body)
                                    .foregroundStyle(Color.LifePilot.textPrimary)
                                Spacer()
                                if let due = task.dueDate {
                                    Text(due.formatted(date: .omitted, time: .shortened))
                                        .font(.LifePilot.caption)
                                        .foregroundStyle(Color.LifePilot.textSecondary)
                                } else {
                                    Text("Inbox")
                                        .font(.LifePilot.caption)
                                        .foregroundStyle(Color.LifePilot.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var transitSection: some View {
        if viewModel.transitConfigured {
            TransitBriefingSection(
                departures: viewModel.transitDepartures,
                statuses: viewModel.transitStatuses,
                fetchedAt: viewModel.transitFetchedAt,
                source: viewModel.transitSource,
                stopName: viewModel.transitStopName,
                isStale: viewModel.transitIsStale
            )
        }
    }

    @ViewBuilder
    private var preparedSection: some View {
        if viewModel.recommendations.count > 1 {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Also prepared", symbolName: "sparkle")
                VStack(spacing: Spacing.sm) {
                    ForEach(
                        Array(viewModel.recommendations.dropFirst().enumerated()),
                        id: \.offset
                    ) { index, content in
                        BriefingCard(content: content)
                            .lifePilotAnimation(Motion.spring, reduceMotion: reduceMotion, value: index)
                    }
                }
            }
        }
    }

    private var upcomingScheduleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Upcoming schedule", symbolName: "calendar")

            if viewModel.upcomingEvents.isEmpty {
                EmptyStateView(
                    symbolName: "calendar",
                    message: "Nothing else on your calendar soon."
                )
            } else {
                GlowCard {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.upcomingEvents.prefix(3))) { event in
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

    private var freshnessFooter: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(viewModel.freshnessSummary)
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textSecondary)
            if let updated = viewModel.lastUpdated {
                Text("Updated \(updated.formatted(date: .omitted, time: .shortened))")
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }
            Button("Refresh") {
                Task { await viewModel.refresh() }
            }
            .font(.LifePilot.caption)
        }
        .accessibilityElement(children: .combine)
    }

    private var orientationLine: String {
        if let leaveBy = viewModel.leaveBySummary {
            return "\(leaveBy). You still have time to prepare."
        }
        if viewModel.upcomingEvents.count >= 4 {
            return "A full day. Protect the gaps between commitments."
        }
        if !viewModel.topTasks.isEmpty {
            return "A few priorities, with room to move."
        }
        return "A quiet day. Add only what matters."
    }

}

private struct TransitBriefingSection: View {
    let departures: [TransitDeparture]
    let statuses: [TransitLineStatus]
    let fetchedAt: Date?
    let source: String?
    let stopName: String?
    let isStale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: title, symbolName: "tram.fill")
            if departures.isEmpty, statuses.isEmpty {
                EmptyStateView(
                    symbolName: "tram",
                    message: "No matching transit data is available right now."
                )
            } else {
                transitCard
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var transitCard: some View {
        GlowCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(statuses) { status in
                    Label(
                        "\(status.lineName): \(status.statusDescription)",
                        systemImage: status.isGoodService
                            ? "checkmark.circle.fill"
                            : "exclamationmark.triangle.fill"
                    )
                    .font(.LifePilot.caption)
                    .foregroundStyle(status.isGoodService
                        ? Color.LifePilot.signalSuccess
                        : Color.LifePilot.signalRisk)
                }
                ForEach(Array(departures.prefix(4))) { departure in
                    departureRow(departure)
                }
                Text(attribution)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }
        }
    }

    private func departureRow(_ departure: TransitDeparture) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("\(departure.lineName) to \(departure.destination)")
                    .font(.LifePilot.body)
                if let platform = departure.platform {
                    Text(platform)
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
            }
            Spacer()
            Text(departure.etaLabel)
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textSecondary)
        }
    }

    private var attribution: String {
        let provider = source ?? "Transit provider"
        let freshness = isStale ? "Cached - may be stale" : "Live"
        if let fetchedAt {
            return "\(provider) - \(freshness) - updated "
                + fetchedAt.formatted(date: .omitted, time: .shortened)
        }
        return "\(provider) - \(freshness)"
    }

    private var title: String {
        stopName.map { "Transit - \($0)" } ?? "Live transit"
    }
}
