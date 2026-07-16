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
    public private(set) var freshnessSummary: String = "Local"
    public private(set) var lastUpdated: Date?
    public private(set) var loadState: LoadableState<Bool> = .idle
    public private(set) var isLoading = false

    private let taskStore: any TaskStore
    private let eventStore: any EventStore
    private let preferenceStore: any PreferenceStore
    private let planningEngine: any PlanningEngine
    private let calendarIntegration: any CalendarIntegrating
    private let clock: any ClockProviding

    public init(
        taskStore: any TaskStore,
        eventStore: any EventStore,
        preferenceStore: any PreferenceStore,
        planningEngine: any PlanningEngine = DeterministicPlanningEngine(),
        calendarIntegration: any CalendarIntegrating = UnavailableCalendarIntegration(),
        clock: any ClockProviding = SystemClock()
    ) {
        self.taskStore = taskStore
        self.eventStore = eventStore
        self.preferenceStore = preferenceStore
        self.planningEngine = planningEngine
        self.calendarIntegration = calendarIntegration
        self.clock = clock
    }

    public func load() async {
        isLoading = true
        loadState = .loading
        defer { isLoading = false }

        let now = clock.now()
        let preferences = await preferenceStore.loadPreferences()
        var events = await eventStore.allEvents()
        let tasks = await taskStore.allTasks()

        var freshnessNotes: [String] = ["Local data"]
        let calendarState = await calendarIntegration.authorizationState()
        if calendarState == .authorized || calendarState == .limited {
            let dayStart = Calendar.current.startOfDay(for: now)
            let dayEnd = Calendar.current.date(byAdding: .day, value: 2, to: dayStart) ?? now
            if let remote = try? await calendarIntegration.fetchEvents(from: dayStart, to: dayEnd) {
                events = mergeEvents(local: events, remote: remote)
                freshnessNotes.append("Calendar connected")
            } else {
                freshnessNotes.append("Calendar unavailable — showing local")
            }
        } else if calendarState == .denied {
            freshnessNotes.append("Calendar denied")
        }

        let openTasks = tasks.filter { !$0.isCompleted }
        topTasks = openTasks
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

        findings = planningEngine.analyze(
            events: events,
            tasks: tasks,
            preferences: preferences,
            now: now
        )

        recommendations = findings.prefix(6).map { finding in
            let evidence = finding.evidence.first?.summary ?? finding.detail
            return BriefingCard.Content(
                title: finding.title,
                reasoning: evidence,
                sourceAgent: finding.evidence.first?.sourceAgent ?? .planning,
                riskBadgeText: finding.riskLevel == .low ? nil : finding.riskLevel.rawValue.capitalized
            )
        }

        greeting = Self.greeting(for: now)
        dateText = now.formatted(.dateTime.weekday(.wide).month(.wide).day())
        freshnessSummary = freshnessNotes.joined(separator: " · ")
        lastUpdated = now
        loadState = recommendations.isEmpty && upcomingEvents.isEmpty && topTasks.isEmpty
            ? .empty
            : .loaded(true)
    }

    public func refresh() async {
        await load()
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
