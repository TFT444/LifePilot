import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Morning Briefing / Today home — store and planning backed.
public struct HomeView: View {
    @State private var viewModel: HomeViewModel

    public init(
        taskStore: any TaskStore,
        eventStore: any EventStore,
        preferenceStore: any PreferenceStore,
        planningEngine: any PlanningEngine = DeterministicPlanningEngine(),
        calendarIntegration: any CalendarIntegrating = UnavailableCalendarIntegration()
    ) {
        _viewModel = State(
            initialValue: HomeViewModel(
                taskStore: taskStore,
                eventStore: eventStore,
                preferenceStore: preferenceStore,
                planningEngine: planningEngine,
                calendarIntegration: calendarIntegration
            )
        )
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                heroHeader
                prioritiesSection
                preparedSection
                upcomingScheduleSection
                freshnessFooter
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.LifePilot.backgroundPrimary)
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.load() }
    }

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

    private var prioritiesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Top priorities", symbolName: "checkmark.circle")

            if viewModel.topTasks.isEmpty {
                EmptyStateView(
                    symbolName: "checkmark.circle",
                    message: "No open tasks — capture something when you’re ready."
                )
            } else {
                CardContainer {
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
                    ForEach(Array(viewModel.recommendations.enumerated()), id: \.offset) { _, content in
                        BriefingCard(content: content)
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
