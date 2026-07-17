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
    public let approvalStore: any ApprovalStore
    public let planningEngine: any PlanningEngine
    public let actionExecutor: any ActionExecuting
    public let notificationScheduler: any NotificationScheduling
    public let calendarIntegration: any CalendarIntegrating
    public let remindersIntegration: any RemindersIntegrating
    public let weatherIntegration: any WeatherIntegrating
    public let travelIntegration: any TravelTimeIntegrating
    public let cloudSync: any CloudSyncIntegrating

    public init(
        ghostBrain: GhostBrainServing,
        timelineProvider: TimelineProviding,
        taskStore: any TaskStore,
        eventStore: any EventStore,
        preferenceStore: any PreferenceStore,
        approvalStore: any ApprovalStore = InMemoryApprovalStore(),
        planningEngine: any PlanningEngine = DeterministicPlanningEngine(),
        actionExecutor: any ActionExecuting,
        notificationScheduler: any NotificationScheduling = NoOpNotificationScheduler(),
        calendarIntegration: any CalendarIntegrating = UnavailableCalendarIntegration(),
        remindersIntegration: any RemindersIntegrating = UnavailableRemindersIntegration(),
        weatherIntegration: any WeatherIntegrating = UnavailableWeatherIntegration(),
        travelIntegration: any TravelTimeIntegrating = UnavailableTravelTimeIntegration(),
        cloudSync: any CloudSyncIntegrating = DisabledCloudSyncIntegration()
    ) {
        self.ghostBrain = ghostBrain
        self.timelineProvider = timelineProvider
        self.taskStore = taskStore
        self.eventStore = eventStore
        self.preferenceStore = preferenceStore
        self.approvalStore = approvalStore
        self.planningEngine = planningEngine
        self.actionExecutor = actionExecutor
        self.notificationScheduler = notificationScheduler
        self.calendarIntegration = calendarIntegration
        self.remindersIntegration = remindersIntegration
        self.weatherIntegration = weatherIntegration
        self.travelIntegration = travelIntegration
        self.cloudSync = cloudSync
    }

    /// Production wiring: SwiftData-backed stores, real notification scheduler,
    /// EventKit / MapKit adapters (graceful when denied), deterministic planning.
    /// Under XCTest / SPM test host, uses in-memory SwiftData and no-op system
    /// adapters because `UNUserNotificationCenter` / EventKit require an app bundle.
    public static var live: AppDependencies {
        let testing = Self.isRunningUnitTests
        let cloudSync = OptionalCloudKitSyncIntegration()
        let cloudEnabled = !testing && UserDefaults.standard.bool(
            forKey: OptionalCloudKitSyncIntegration.enabledDefaultsKey
        )
        let controller: PersistenceController
        if testing, let memory = try? PersistenceController(inMemory: true) {
            controller = memory
        } else if let disk = try? PersistenceController(
            inMemory: false,
            cloudKitEnabled: cloudEnabled
        ) {
            controller = disk
        } else {
            controller = PersistenceController.shared
        }
        let taskStore = SwiftDataTaskStore(container: controller.container)
        let eventStore = SwiftDataEventStore(container: controller.container)
        let preferenceStore = SwiftDataPreferenceStore(container: controller.container)
        let approvalStore = SwiftDataApprovalStore(container: controller.container)
        let executor = LocalActionExecutor(taskStore: taskStore, eventStore: eventStore)
        return AppDependencies(
            ghostBrain: GhostBrainService(),
            timelineProvider: StoreBackedTimelineProvider(
                taskStore: taskStore,
                eventStore: eventStore
            ),
            taskStore: taskStore,
            eventStore: eventStore,
            preferenceStore: preferenceStore,
            approvalStore: approvalStore,
            planningEngine: DeterministicPlanningEngine(),
            actionExecutor: executor,
            notificationScheduler: testing
                ? NoOpNotificationScheduler()
                : UserNotificationsScheduler(),
            calendarIntegration: testing
                ? UnavailableCalendarIntegration()
                : EventKitCalendarIntegration(),
            remindersIntegration: testing
                ? UnavailableRemindersIntegration()
                : EventKitRemindersIntegration(),
            weatherIntegration: testing
                ? UnavailableWeatherIntegration()
                : WeatherKitIntegration(),
            travelIntegration: testing
                ? UnavailableTravelTimeIntegration()
                : MapKitTravelTimeIntegration(),
            cloudSync: testing ? DisabledCloudSyncIntegration() : cloudSync
        )
    }

    private static var isRunningUnitTests: Bool {
        let process = ProcessInfo.processInfo
        if process.processName == "xctest" {
            return true
        }
        if process.environment["XCTestConfigurationFilePath"] != nil {
            return true
        }
        if process.environment["XCTestBundlePath"] != nil {
            return true
        }
        return NSClassFromString("XCTestCase") != nil
    }

    /// Preview / demo wiring with seeded in-memory stores.
    public static var preview: AppDependencies {
        let taskStore = InMemoryTaskStore(seed: MockTasks.items())
        let eventStore = InMemoryEventStore(seed: MockCalendar.events())
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
            approvalStore: InMemoryApprovalStore(),
            planningEngine: DeterministicPlanningEngine(),
            actionExecutor: executor,
            notificationScheduler: NoOpNotificationScheduler(),
            calendarIntegration: UnavailableCalendarIntegration(),
            remindersIntegration: UnavailableRemindersIntegration(),
            weatherIntegration: StaticWeatherIntegration(snapshot: MockWeather.snapshot()),
            travelIntegration: StaticTravelTimeIntegration(minutes: 18),
            cloudSync: DisabledCloudSyncIntegration()
        )
    }
}
