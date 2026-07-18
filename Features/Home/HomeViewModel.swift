import Foundation
import LifePilotCore
import LifePilotDesignSystem

/// Optional system integrations for Home briefing enrichment.
public struct HomeBriefingIntegrations: Sendable {
    public var calendar: any CalendarIntegrating
    public var weather: any WeatherIntegrating
    public var travel: any TravelTimeIntegrating
    public var location: any LocationProviding

    public init(
        calendar: any CalendarIntegrating = UnavailableCalendarIntegration(),
        weather: any WeatherIntegrating = UnavailableWeatherIntegration(),
        travel: any TravelTimeIntegrating = UnavailableTravelTimeIntegration(),
        location: any LocationProviding = UnavailableLocationProvider()
    ) {
        self.calendar = calendar
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
    public private(set) var greeting: String = ""
    public private(set) var dateText: String = ""
    public private(set) var recommendations: [BriefingCard.Content] = []
    public private(set) var upcomingEvents: [CalendarEvent] = []
    public private(set) var topTasks: [TaskItem] = []
    public private(set) var findings: [PlanningFinding] = []
    public private(set) var weatherSummary: String?
    public private(set) var leaveBySummary: String?
    public private(set) var freshnessSummary: String = "Local"
    public private(set) var lastUpdated: Date?
    public private(set) var statusBanner: HomeStatusBanner?
    public private(set) var loadState: LoadableState<Bool> = .idle
    public private(set) var isLoading = false

    private let taskStore: any TaskStore
    private let eventStore: any EventStore
    private let preferenceStore: any PreferenceStore
    private let planningEngine: any PlanningEngine
    private let integrations: HomeBriefingIntegrations
    private let clock: any ClockProviding

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
        let tasks = await taskStore.allTasks()
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
            tasks: tasks,
            events: hydrated.events,
            extraFindings: leaveBy.findings
        )
        leaveBySummary = leaveBy.summary
        weatherSummary = weather.map {
            "\($0.temperatureFahrenheit)° \($0.condition.rawValue)"
        }

        var notes = hydrated.notes
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

    private func makeStatusBanner(
        calendarNotes: [String],
        hasWeather: Bool
    ) async -> HomeStatusBanner? {
        let calendarState = await integrations.calendar.authorizationState()
        if calendarState == .denied {
            return HomeStatusBanner(
                message: "Calendar access denied — showing LifePilot-owned events only.",
                style: .warning
            )
        }
        let locationState = await integrations.location.authorizationState()
        if locationState == .denied {
            return HomeStatusBanner(
                message: "Location denied — weather and live leave-by are limited.",
                style: .warning
            )
        }
        if calendarNotes.contains(where: { $0.localizedCaseInsensitiveContains("unavailable") }) {
            return HomeStatusBanner(
                message: "Calendar temporarily unavailable — local schedule is shown.",
                style: .info
            )
        }
        if !hasWeather, locationState == .notDetermined {
            return HomeStatusBanner(
                message: "Enable Location in Settings for weather context.",
                style: .info
            )
        }
        return nil
    }

    public func refresh() async {
        await load()
    }

    private func hydrateEvents(now: Date) async -> (events: [CalendarEvent], notes: [String]) {
        var events = await eventStore.allEvents()
        var notes = ["Local data"]
        let calendarState = await integrations.calendar.authorizationState()
        if calendarState == .authorized || calendarState == .limited {
            let dayStart = Calendar.current.startOfDay(for: now)
            let dayEnd = Calendar.current.date(byAdding: .day, value: 2, to: dayStart) ?? now
            if let remote = try? await integrations.calendar.fetchEvents(from: dayStart, to: dayEnd) {
                events = mergeEvents(local: events, remote: remote)
                notes.append("Calendar connected")
            } else {
                notes.append("Calendar unavailable — showing local")
            }
        } else if calendarState == .denied {
            notes.append("Calendar denied")
        }
        return (events, notes)
    }

    private func enrichLeaveBy(
        events: [CalendarEvent],
        weather: WeatherSnapshot?,
        preferences: UserPreferences,
        now: Date
    ) async -> (findings: [PlanningFinding], summary: String?) {
        let candidates = events
            .filter { $0.status != .declined && !$0.isAllDay && $0.startDate > now }
            .sorted { $0.startDate < $1.startDate }
        guard let next = candidates.first else {
            return ([], nil)
        }

        var findings: [PlanningFinding] = []
        let travel = await travelFinding(
            for: next,
            weather: weather,
            preferences: preferences,
            now: now
        )
        if let travel {
            findings.append(travel)
        }
        if let weather {
            if let weatherFinding = LeaveByPlanner.weatherFinding(
                for: next,
                weather: weather,
                now: now
            ) {
                findings.append(weatherFinding)
            }
        }
        return (findings, travel?.suggestedActionSummary)
    }

    private func travelFinding(
        for event: CalendarEvent,
        weather: WeatherSnapshot?,
        preferences: UserPreferences,
        now: Date
    ) async -> PlanningFinding? {
        guard let location = event.location, !location.isEmpty else { return nil }
        if let minutes = try? await integrations.travel.travelTimeMinutes(
            from: "Current Location",
            to: location,
            departingAt: now
        ) {
            return LeaveByPlanner.finding(
                for: event,
                travelMinutes: minutes,
                weather: weather,
                now: now,
                extraBufferMinutes: max(0, preferences.defaultTravelBufferMinutes / 3)
            )
        }
        let hasBuffer = event.travelBufferMinutes > 0
            || preferences.defaultTravelBufferMinutes > 0
        guard hasBuffer else { return nil }
        let minutes = max(event.travelBufferMinutes, preferences.defaultTravelBufferMinutes)
        return LeaveByPlanner.finding(
            for: event,
            travelMinutes: minutes,
            weather: weather,
            now: now
        )
    }

    private func applyBriefing(
        now: Date,
        preferences: UserPreferences,
        tasks: [TaskItem],
        events: [CalendarEvent],
        extraFindings: [PlanningFinding]
    ) {
        topTasks = tasks.filter { !$0.isCompleted }
            .sorted { lhs, rhs in
                (lhs.dueDate ?? .distantFuture, lhs.priority) < (rhs.dueDate ?? .distantFuture, rhs.priority)
            }
            .prefix(5)
            .map { $0 }

        upcomingEvents = events
            .filter { $0.startDate >= now && $0.status != .declined }
            .sorted { $0.startDate < $1.startDate }
            .prefix(6)
            .map { $0 }

        var combined = planningEngine.analyze(
            events: events,
            tasks: tasks,
            preferences: preferences,
            now: now
        )
        combined.append(contentsOf: extraFindings)
        findings = combined
        recommendations = findings.prefix(6).map { finding in
            BriefingCard.Content(
                title: finding.title,
                reasoning: finding.evidence.first?.summary ?? finding.detail,
                sourceAgent: finding.evidence.first?.sourceAgent ?? .planning,
                riskBadgeText: finding.riskLevel == .low ? nil : finding.riskLevel.rawValue.capitalized
            )
        }
        greeting = Self.greeting(for: now)
        dateText = now.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private func mergeEvents(local: [CalendarEvent], remote: [CalendarEvent]) -> [CalendarEvent] {
        var byExternal: [String: CalendarEvent] = [:]
        for event in local {
            if let key = event.externalIdentifier {
                byExternal[key] = event
            }
        }
        var merged = local.filter { $0.externalIdentifier == nil }
        for remoteEvent in remote {
            if let key = remoteEvent.externalIdentifier, byExternal[key] == nil {
                merged.append(remoteEvent)
            } else if remoteEvent.externalIdentifier == nil {
                merged.append(remoteEvent)
            }
        }
        return merged
    }

    private static func greeting(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5 ..< 12: return "Good morning"
        case 12 ..< 17: return "Good afternoon"
        case 17 ..< 22: return "Good evening"
        default: return "Hello"
        }
    }
}
