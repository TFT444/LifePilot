import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Evidence-based insights from local tasks and events — no finance/medical claims.
public struct InsightsView: View {
    @State private var viewModel: InsightsViewModel

    public init(
        taskStore: any TaskStore,
        eventStore: any EventStore,
        preferenceStore: any PreferenceStore
    ) {
        _viewModel = State(
            initialValue: InsightsViewModel(
                taskStore: taskStore,
                eventStore: eventStore,
                preferenceStore: preferenceStore
            )
        )
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if viewModel.insights.isEmpty {
                    EmptyStateView(
                        symbolName: "chart.line.uptrend.xyaxis",
                        message: viewModel.statusMessage
                    )
                } else {
                    ForEach(viewModel.insights) { insight in
                        insightRow(insight)
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .background(AmbientBackground())
        .navigationTitle("Insights")
        .task { await viewModel.load() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink("Memory") {
                    MemoryView(preferenceStore: viewModel.preferenceStore)
                }
            }
        }
    }

    private func insightRow(_ insight: LifeInsight) -> some View {
        GlowCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(insight.title)
                    .font(.LifePilot.titleMedium)
                    .foregroundStyle(Color.LifePilot.textPrimary)
                Text(insight.detail)
                    .font(.LifePilot.body)
                    .foregroundStyle(Color.LifePilot.textPrimary)
                Text("Evidence: \(insight.evidence)")
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
                Text("Method: \(insight.method)")
                    .font(.caption2)
                    .foregroundStyle(Color.LifePilot.textSecondary)
                Button("Dismiss") {
                    viewModel.dismiss(insight)
                }
                .font(.LifePilot.caption)
            }
        }
    }
}

public struct LifeInsight: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var detail: String
    public var evidence: String
    public var method: String

    public init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        evidence: String,
        method: String
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.evidence = evidence
        self.method = method
    }
}

@Observable
@MainActor
public final class InsightsViewModel {
    public private(set) var insights: [LifeInsight] = []
    public private(set) var statusMessage =
        "Need a bit more local history before insights appear."
    public let preferenceStore: any PreferenceStore

    let taskStore: any TaskStore
    let eventStore: any EventStore
    var dismissed = Set<String>()

    public init(
        taskStore: any TaskStore,
        eventStore: any EventStore,
        preferenceStore: any PreferenceStore
    ) {
        self.taskStore = taskStore
        self.eventStore = eventStore
        self.preferenceStore = preferenceStore
    }

    public func load() async {
        let tasks = await taskStore.allTasks()
        let events = await eventStore.allEvents()
        let preferences = await preferenceStore.loadPreferences()
        let built = buildInsights(tasks: tasks, events: events, preferences: preferences)
        insights = built
        if built.isEmpty {
            statusMessage = "Keep using tasks and events locally — insights appear when "
                + "there is enough evidence (never financial or medical)."
        }
    }

    public func dismiss(_ insight: LifeInsight) {
        dismissed.insert(insight.title.lowercased().replacingOccurrences(of: " ", with: "-"))
        insights.removeAll { $0.id == insight.id }
    }

    func isDismissed(_ key: String) -> Bool {
        dismissed.contains(key)
    }
}
