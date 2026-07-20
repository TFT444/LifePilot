import Foundation
import LifePilotCore
import LifePilotDesignSystem

/// Optional system integrations for Home briefing enrichment.
public struct HomeBriefingIntegrations: Sendable {
    public var calendar: any CalendarIntegrating
    public var reminders: any RemindersIntegrating
    public var weather: any WeatherIntegrating
    public var travel: any TravelTimeIntegrating
    public var location: any LocationProviding

    public init(
        calendar: any CalendarIntegrating = UnavailableCalendarIntegration(),
        reminders: any RemindersIntegrating = UnavailableRemindersIntegration(),
        weather: any WeatherIntegrating = UnavailableWeatherIntegration(),
        travel: any TravelTimeIntegrating = UnavailableTravelTimeIntegration(),
        location: any LocationProviding = UnavailableLocationProvider()
    ) {
        self.calendar = calendar
        self.reminders = reminders
        self.weather = weather
        self.travel = travel
        self.location = location
    }
}

/// User-visible recovery banner on Home.
public struct HomeStatusBanner: Equatable, Sendable {
    public var message: String
    public var style: StatusBanner.Style

    public init(message: String, style: StatusBanner.Style) {
        self.message = message
        self.style = style
    }
}

/// Store- and planning-backed Home / Morning Briefing state.
@Observable
@MainActor
public final class HomeViewModel {
    public internal(set) var greeting: String = ""
    public internal(set) var dateText: String = ""
    public internal(set) var recommendations: [BriefingCard.Content] = []
    public internal(set) var upcomingEvents: [CalendarEvent] = []
    public internal(set) var topTasks: [TaskItem] = []
    public internal(set) var findings: [PlanningFinding] = []
    public internal(set) var weatherSummary: String?
    public internal(set) var leaveBySummary: String?
    public internal(set) var freshnessSummary: String = "Local"
    public internal(set) var lastUpdated: Date?
    public internal(set) var statusBanner: HomeStatusBanner?
    public internal(set) var loadState: LoadableState<Bool> = .idle
    public internal(set) var isLoading = false

    let taskStore: any TaskStore
    let eventStore: any EventStore
    let preferenceStore: any PreferenceStore
    let planningEngine: any PlanningEngine
    let integrations: HomeBriefingIntegrations
    let clock: any ClockProviding

    public init(
        taskStore: any TaskStore,
        eventStore: any EventStore,
        preferenceStore: any PreferenceStore,
        planningEngine: any PlanningEngine = DeterministicPlanningEngine(),
        integrations: HomeBriefingIntegrations = HomeBriefingIntegrations(),
        clock: any ClockProviding = SystemClock()
    ) {
        self.taskStore = taskStore
        self.eventStore = eventStore
        self.preferenceStore = preferenceStore
        self.planningEngine = planningEngine
        self.integrations = integrations
        self.clock = clock
    }

    public func load() async {
        isLoading = true
        loadState = .loading
        defer { isLoading = false }

        let now = clock.now()
        let preferences = await preferenceStore.loadPreferences()
        let localTasks = await taskStore.allTasks()
        let hydratedTasks = await hydrateTasks(local: localTasks)
        let hydrated = await hydrateEvents(now: now)
        let weather = try? await integrations.weather.currentWeather()
        let leaveBy = await enrichLeaveBy(
            events: hydrated.events,
            weather: weather,
            preferences: preferences,
            now: now
        )

        applyBriefing(
            now: now,
            preferences: preferences,
            tasks: hydratedTasks.tasks,
            events: hydrated.events,
            extraFindings: leaveBy.findings
        )
        leaveBySummary = leaveBy.summary
        weatherSummary = weather.map {
            "\($0.temperatureFahrenheit)° \($0.condition.rawValue)"
        }

        var notes = hydrated.notes
        notes.append(contentsOf: hydratedTasks.notes)
        if weather != nil {
            notes.append("Weather")
        }
        if leaveBy.summary != nil {
            notes.append("Leave-by")
        }
        freshnessSummary = notes.joined(separator: " · ")
        lastUpdated = now
        statusBanner = await makeStatusBanner(
            calendarNotes: hydrated.notes,
            hasWeather: weather != nil
        )
        loadState = recommendations.isEmpty && upcomingEvents.isEmpty && topTasks.isEmpty
            ? .empty
            : .loaded(true)
    }

    public func refresh() async {
        await load()
    }
}
