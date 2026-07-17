import Foundation
import LifePilotCore
import LifePilotDesignSystem

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
    public private(set) var loadState: LoadableState<Bool> = .idle
    public private(set) var isLoading = false

    private let taskStore: any TaskStore
    private let eventStore: any EventStore
    private let preferenceStore: any PreferenceStore
    private let planningEngine: any PlanningEngine
    private let calendarIntegration: any CalendarIntegrating
    private let weatherIntegration: any WeatherIntegrating
    private let travelIntegration: any TravelTimeIntegrating
    private let clock: any ClockProviding

    public init(
        taskStore: any TaskStore,
        eventStore: any EventStore,
        preferenceStore: any PreferenceStore,
        planningEngine: any PlanningEngine = DeterministicPlanningEngine(),
        calendarIntegration: any CalendarIntegrating = UnavailableCalendarIntegration(),
        weatherIntegration: any WeatherIntegrating = UnavailableWeatherIntegration(),
        travelIntegration: any TravelTimeIntegrating = UnavailableTravelTimeIntegration(),
        clock: any ClockProviding = SystemClock()
    ) {
        self.taskStore = taskStore
        self.eventStore = eventStore
        self.preferenceStore = preferenceStore
        self.planningEngine = planningEngine
        self.calendarIntegration = calendarIntegration
        self.weatherIntegration = weatherIntegration
        self.travelIntegration = travelIntegration
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
        let weather = try? await weatherIntegration.currentWeather()
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
            extraFindings: leaveBy.findings,
            weather: weather
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
        loadState = recommendations.isEmpty && upcomingEvents.isEmpty && topTasks.isEmpty
            ? .empty
            : .loaded(true)
    }

    public func refresh() async {
        await load()
    }

    private func hydrateEvents(now: Date) async -> (events: [CalendarEvent], notes: [String]) {
        var events = await eventStore.allEvents()
        var notes = ["Local data"]
        let calendarState = await calendarIntegration.authorizationState()
        if calendarState == .authorized || calendarState == .limited {
            let dayStart = Calendar.current.startOfDay(for: now)
            let dayEnd = Calendar.current.date(byAdding: .day, value: 2, to: dayStart) ?? now
            if let remote = try? await calendarIntegration.fetchEvents(from: dayStart, to: dayEnd) {
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
        var summary: String?

        if let location = next.location, !location.isEmpty {
            let origin = "Current Location"
            if let minutes = try? await travelIntegration.travelTimeMinutes(
                from: origin,
                to: location,
                departingAt: now
            ) {
                if let finding = LeaveByPlanner.finding(
                    for: next,
                    travelMinutes: minutes,
                    weather: weather,
                    now: now,
                    extraBufferMinutes: max(0, preferences.defaultTravelBufferMinutes / 3)
                ) {
                    findings.append(finding)
                    summary = finding.suggestedActionSummary
                }
            } else if next.travelBufferMinutes > 0
                || preferences.defaultTravelBufferMinutes > 0
            {
                let minutes = max(next.travelBufferMinutes, preferences.defaultTravelBufferMinutes)
                if let finding = LeaveByPlanner.finding(
                    for: next,
                    travelMinutes: minutes,
                    weather: weather,
                    now: now
                ) {
                    findings.append(finding)
                    summary = finding.suggestedActionSummary
                }
            }
        }

        if let weather,
           let weatherFinding = LeaveByPlanner.weatherFinding(for: next, weather: weather, now: now)
        {
            findings.append(weatherFinding)
        }

        return (findings, summary)
    }

    private func applyBriefing(
        now: Date,
        preferences: UserPreferences,
        tasks: [TaskItem],
        events: [CalendarEvent],
        extraFindings: [PlanningFinding],
        weather _: WeatherSnapshot?
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
