import Foundation
import LifePilotCore
import LifePilotDesignSystem

extension HomeViewModel {
    func makeStatusBanner(
        calendarNotes: [String],
        hasWeather: Bool,
        transitError: String?
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
        if let transitError {
            return HomeStatusBanner(
                message: "Transit could not refresh - \(transitError)",
                style: .info
            )
        }
        return nil
    }

    func hydrateEvents(now: Date) async -> (events: [CalendarEvent], notes: [String]) {
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

    func hydrateTasks(local: [TaskItem]) async -> (tasks: [TaskItem], notes: [String]) {
        let remindersState = await integrations.reminders.authorizationState()
        if remindersState == .authorized || remindersState == .limited {
            if let reminders = try? await integrations.reminders.fetchOpenReminders() {
                return (local + reminders, ["Reminders connected"])
            }
            return (local, ["Reminders unavailable - showing local tasks"])
        }
        if remindersState == .denied || remindersState == .restricted {
            return (local, ["Reminders unavailable - showing local tasks"])
        }
        return (local, [])
    }

    func enrichLeaveBy(
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

    func travelFinding(
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

    func applyBriefing(
        now: Date,
        preferences: UserPreferences,
        tasks: [TaskItem],
        events: [CalendarEvent],
        extraFindings: [PlanningFinding]
    ) {
        topTasks = tasks.filter { !$0.isCompleted }
            .sorted { lhs, rhs in
                (lhs.dueDate ?? .distantFuture, lhs.priority)
                    < (rhs.dueDate ?? .distantFuture, rhs.priority)
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
                riskBadgeText: finding.riskLevel == .low
                    ? nil
                    : finding.riskLevel.rawValue.capitalized
            )
        }
        greeting = Self.greeting(for: now)
        dateText = now.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    func mergeEvents(local: [CalendarEvent], remote: [CalendarEvent]) -> [CalendarEvent] {
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

    static func greeting(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5 ..< 12: return "Good morning"
        case 12 ..< 17: return "Good afternoon"
        case 17 ..< 22: return "Good evening"
        default: return "Hello"
        }
    }
}
