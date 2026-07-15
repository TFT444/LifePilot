import Foundation
import LifePilotCore
import LifePilotGhostBrain
import LifePilotMocks
import LifePilotServices

/// Composition root: wires Core protocols to concrete services and mocks.
/// Features never import Services or Mocks directly.
public struct AppDependencies: Sendable {
    public let ghostBrain: GhostBrainServing
    public let timelineProvider: TimelineProviding
    public let taskStore: any TaskStore
    public let eventStore: any EventStore
    public let preferenceStore: any PreferenceStore
    public let planningEngine: any PlanningEngine
    public let actionExecutor: any ActionExecuting

    public init(
        ghostBrain: GhostBrainServing,
        timelineProvider: TimelineProviding,
        taskStore: any TaskStore,
        eventStore: any EventStore,
        preferenceStore: any PreferenceStore,
        planningEngine: any PlanningEngine = DeterministicPlanningEngine(),
        actionExecutor: any ActionExecuting
    ) {
        self.ghostBrain = ghostBrain
        self.timelineProvider = timelineProvider
        self.taskStore = taskStore
        self.eventStore = eventStore
        self.preferenceStore = preferenceStore
        self.planningEngine = planningEngine
        self.actionExecutor = actionExecutor
    }

    /// Offline-capable default for the daily-life MVP: seeded in-memory stores
    /// plus deterministic mock briefing content.
    public static var live: AppDependencies {
        let tasks = MockTasks.items()
        let events = MockCalendar.events()
        let taskStore = InMemoryTaskStore(seed: tasks)
        let eventStore = InMemoryEventStore(seed: events)
        let executor = LocalActionExecutor(taskStore: taskStore, eventStore: eventStore)
        return AppDependencies(
            ghostBrain: MockRecommendationProvider(),
            timelineProvider: StoreBackedTimelineProvider(
                taskStore: taskStore,
                eventStore: eventStore
            ),
            taskStore: taskStore,
            eventStore: eventStore,
            preferenceStore: InMemoryPreferenceStore(),
            planningEngine: DeterministicPlanningEngine(),
            actionExecutor: executor
        )
    }
}
