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
        Group {
            if viewModel.insights.isEmpty {
                EmptyStateView(
                    symbolName: "chart.line.uptrend.xyaxis",
                    message: viewModel.statusMessage
                )
            } else {
                List {
                    ForEach(viewModel.insights) { insight in
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(insight.title)
                                .font(.LifePilot.titleMedium)
                            Text(insight.detail)
                                .font(.LifePilot.body)
                                .foregroundStyle(Color.LifePilot.textPrimary)
                            Text("Evidence: \(insight.evidence)")
                                .font(.LifePilot.caption)
                                .foregroundStyle(Color.LifePilot.textSecondary)
                            Text("Method: \(insight.method)")
                                .font(.caption2)
                                .foregroundStyle(Color.LifePilot.textSecondary)
                        }
                        .padding(.vertical, Spacing.xs)
                        .swipeActions {
                            Button {
                                viewModel.dismiss(insight)
                            } label: {
                                Label("Dismiss", systemImage: "eye.slash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color.LifePilot.backgroundPrimary)
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

    private let taskStore: any TaskStore
    private let eventStore: any EventStore
    private var dismissed = Set<String>()

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
        var built: [LifeInsight] = []

        let completed = tasks.filter(\.isCompleted).count
        let open = tasks.filter { !$0.isCompleted }.count
        if completed + open >= 3 {
            let key = "task-completion"
            if !dismissed.contains(key) {
                built.append(
                    LifeInsight(
                        title: "Task completion",
                        detail: "\(completed) completed, \(open) still open.",
                        evidence: "Counted \(completed + open) local tasks.",
                        method: "completed / total open+completed counts"
                    )
                )
            }
        }

        let workMeetings = events.filter {
            $0.context == .work || $0.eventKind == .meeting
        }
        if workMeetings.count >= 2 {
            let minutes = workMeetings.reduce(0) {
                $0 + Int($1.endDate.timeIntervalSince($1.startDate) / 60)
            }
            let key = "meeting-load"
            if !dismissed.contains(key) {
                built.append(
                    LifeInsight(
                        title: "Meeting load",
                        detail: "\(workMeetings.count) work/meeting blocks totaling ~\(minutes) minutes.",
                        evidence: "Sum of local work/meeting event durations.",
                        method: "count + duration sum of work/meeting events"
                    )
                )
            }
        }

        let outside = workMeetings.filter { event in
            let hour = Calendar.current.component(.hour, from: event.startDate)
            return hour < preferences.workDayStartHour || hour >= preferences.workDayEndHour
        }
        if !outside.isEmpty {
            let key = "work-boundary"
            if !dismissed.contains(key) {
                built.append(
                    LifeInsight(
                        title: "Work/life boundary",
                        detail: "\(outside.count) meetings sit outside configured work hours.",
                        evidence: "Compared event start hours to Settings work hours.",
                        method: "hour vs workDayStartHour/workDayEndHour"
                    )
                )
            }
        }

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
}
