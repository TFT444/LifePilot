import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Morning Briefing / Today home — Phase 2 dark-glass composition.
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
                contextGrid
                prioritiesSection
                preparedSection
                upcomingScheduleSection
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

                Text("Here’s what matters today.")
                    .font(.LifePilot.body)
                    .foregroundStyle(Color.LifePilot.textSecondary)

                if let leaveBy = viewModel.leaveBySummary {
                    Text(leaveBy)
                        .font(.LifePilot.titleMedium)
                        .foregroundStyle(Color.LifePilot.accentEnd)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var contextGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: Spacing.md
        ) {
            ContextTile(
                symbolName: "cloud.sun.fill",
                title: viewModel.weatherSummary ?? "Weather",
                subtitle: viewModel.weatherSummary == nil
                    ? "Connect location in Settings"
                    : "Local conditions",
                accent: Color.LifePilot.accentEnd
            )
            ContextTile(
                symbolName: "airplane.departure",
                title: viewModel.leaveBySummary ?? "Travel",
                subtitle: viewModel.upcomingEvents.first?.title ?? "No trip soon",
                accent: Color.LifePilot.accentStart
            )
            ContextTile(
                symbolName: "calendar",
                title: "\(viewModel.upcomingEvents.count) upcoming",
                subtitle: viewModel.upcomingEvents.first.map {
                    $0.startDate.formatted(date: .omitted, time: .shortened)
                } ?? "Clear schedule",
                accent: Color.LifePilot.signalSuccess
            )
            ContextTile(
                symbolName: "checkmark.circle.fill",
                title: "\(viewModel.topTasks.count) open",
                subtitle: viewModel.topTasks.first?.title ?? "Inbox is clear",
                accent: Color.LifePilot.signalRisk
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
                        ForEach(viewModel.topTasks) { task in
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

    private var preparedSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Prepared for you", symbolName: "sparkle")

            if viewModel.recommendations.isEmpty {
                EmptyStateView(
                    symbolName: "sparkle",
                    message: "No conflicts or risks detected from your local schedule."
                )
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(Array(viewModel.recommendations.enumerated()), id: \.offset) { index, content in
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
}
