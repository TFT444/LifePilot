import Foundation

/// Deterministic daily-life planning rules. Produces findings with evidence;
/// never mutates external data.
public struct DeterministicPlanningEngine: PlanningEngine {
    public init() {}

    public func analyze(
        events: [CalendarEvent],
        tasks: [TaskItem],
        preferences: UserPreferences,
        now: Date
    ) -> [PlanningFinding] {
        var findings: [PlanningFinding] = []
        findings.append(contentsOf: Self.overlappingEvents(events, now: now))
        findings.append(contentsOf: Self.insufficientBuffers(events, preferences: preferences, now: now))
        findings.append(contentsOf: Self.overdueAndAtRiskTasks(tasks, now: now))
        findings.append(contentsOf: Self.outsideWorkHours(events, preferences: preferences))
        findings.append(contentsOf: Self.impossibleWorkload(
            events: events,
            tasks: tasks,
            preferences: preferences,
            now: now
        ))
        return findings
    }

    static func overlappingEvents(_ events: [CalendarEvent], now: Date) -> [PlanningFinding] {
        let active = events
            .filter { $0.status != .declined && !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
        guard active.count >= 2 else { return [] }

        var results: [PlanningFinding] = []
        for index in 0 ..< (active.count - 1) {
            let left = active[index]
            let right = active[index + 1]
            guard left.overlaps(right) else { continue }
            results.append(
                PlanningFinding(
                    kind: .overlappingEvents,
                    title: "Schedule conflict",
                    detail: "“\(left.title)” and “\(right.title)” overlap.",
                    evidence: [
                        EvidenceItem(
                            summary: "“\(left.title)” overlaps “\(right.title)”",
                            sourceAgent: .calendar,
                            observedAt: now,
                            relatedRecordIDs: [left.id, right.id]
                        ),
                    ],
                    confidence: 0.95,
                    riskLevel: .medium,
                    suggestedActionSummary: "Reschedule or shorten one event"
                )
            )
        }
        return results
    }

    static func insufficientBuffers(
        _ events: [CalendarEvent],
        preferences: UserPreferences,
        now: Date
    ) -> [PlanningFinding] {
        let timed = events
            .filter { $0.status != .declined && !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
        guard timed.count >= 2 else { return [] }

        var results: [PlanningFinding] = []
        for index in 0 ..< (timed.count - 1) {
            let earlier = timed[index]
            let later = timed[index + 1]
            let gap = later.startDate.timeIntervalSince(earlier.endDate)
            let travel = max(later.travelBufferMinutes, preferences.defaultTravelBufferMinutes)
            let prep = max(later.preparationMinutes, preferences.defaultPreparationMinutes)
            let needed = TimeInterval(travel + prep) * 60
            guard gap >= 0, gap < needed else { continue }
            results.append(
                PlanningFinding(
                    kind: .insufficientTravelOrPreparation,
                    title: "Tight turnaround before \(later.title)",
                    detail: "Only \(Int(gap / 60)) minutes between events; "
                        + "\(Int(needed / 60)) minutes recommended.",
                    evidence: [
                        EvidenceItem(
                            summary: "Gap \(Int(gap / 60))m < buffer \(Int(needed / 60))m",
                            sourceAgent: .planning,
                            observedAt: now,
                            relatedRecordIDs: [earlier.id, later.id]
                        ),
                    ],
                    confidence: 0.85,
                    riskLevel: .medium,
                    suggestedActionSummary: "Leave earlier or add a travel buffer"
                )
            )
        }
        return results
    }

    static func overdueAndAtRiskTasks(_ tasks: [TaskItem], now: Date) -> [PlanningFinding] {
        var results: [PlanningFinding] = []
        for task in tasks where !task.isCompleted {
            guard let due = task.dueDate else { continue }
            if due < now {
                results.append(
                    PlanningFinding(
                        kind: .overdueTask,
                        title: "Overdue: \(task.title)",
                        detail: "Was due \(due.formatted()).",
                        evidence: [
                            EvidenceItem(
                                summary: "Task past due",
                                sourceAgent: .task,
                                observedAt: now,
                                relatedRecordIDs: [task.id]
                            ),
                        ],
                        confidence: 1.0,
                        riskLevel: .high,
                        suggestedActionSummary: "Complete, snooze, or reschedule"
                    )
                )
            } else if due.timeIntervalSince(now) < 3 * 3600 {
                results.append(
                    PlanningFinding(
                        kind: .atRiskTask,
                        title: "Due soon: \(task.title)",
                        detail: "Due within three hours.",
                        evidence: [
                            EvidenceItem(
                                summary: "Due within 3 hours",
                                sourceAgent: .task,
                                observedAt: now,
                                relatedRecordIDs: [task.id]
                            ),
                        ],
                        confidence: 0.8,
                        riskLevel: .medium,
                        suggestedActionSummary: "Block focus time"
                    )
                )
            }
        }
        return results
    }

    static func outsideWorkHours(
        _ events: [CalendarEvent],
        preferences: UserPreferences
    ) -> [PlanningFinding] {
        let calendar = Calendar.current
        var results: [PlanningFinding] = []
        for event in events where event.eventKind == .meeting || event.context == .work {
            let hour = calendar.component(.hour, from: event.startDate)
            let weekday = calendar.component(.weekday, from: event.startDate)
            let outsideDay = !preferences.workDays.contains(weekday)
            let outsideHours = hour < preferences.workDayStartHour
                || hour >= preferences.workDayEndHour
            guard outsideDay || outsideHours else { continue }
            results.append(
                PlanningFinding(
                    kind: .outsideWorkHours,
                    title: "Meeting outside work hours",
                    detail: "“\(event.title)” starts outside configured work boundaries.",
                    evidence: [
                        EvidenceItem(
                            summary: "Work-hours preference mismatch",
                            sourceAgent: .planning,
                            observedAt: event.startDate,
                            relatedRecordIDs: [event.id]
                        ),
                    ],
                    confidence: 0.75,
                    riskLevel: .low,
                    suggestedActionSummary: "Confirm or move within work hours"
                )
            )
        }
        return results
    }

    static func impossibleWorkload(
        events: [CalendarEvent],
        tasks: [TaskItem],
        preferences: UserPreferences,
        now: Date
    ) -> [PlanningFinding] {
        let calendar = Calendar.current
        guard let dayEnd = calendar.date(
            bySettingHour: 23,
            minute: 59,
            second: 59,
            of: now
        ) else {
            return []
        }

        let remainingEventMinutes = events
            .filter {
                $0.startDate >= now
                    && $0.startDate <= dayEnd
                    && !$0.isAllDay
                    && $0.status != .declined
            }
            .reduce(0) { $0 + Int($1.endDate.timeIntervalSince($1.startDate) / 60) }

        let openTaskMinutes = tasks
            .filter { !$0.isCompleted }
            .reduce(0) { partial, task in
                partial + Int((task.estimatedDuration ?? 30 * 60) / 60)
            }

        let currentHour = calendar.component(.hour, from: now)
        let startHour = max(preferences.workDayStartHour, currentHour)
        let availableMinutes = max(0, preferences.workDayEndHour - startHour) * 60

        guard openTaskMinutes + remainingEventMinutes > availableMinutes + 60 else {
            return []
        }

        return [
            PlanningFinding(
                kind: .impossibleWorkload,
                title: "Day looks overloaded",
                detail: "Estimated \(openTaskMinutes + remainingEventMinutes) minutes "
                    + "against ~\(availableMinutes) available.",
                evidence: [
                    EvidenceItem(
                        summary: "Workload exceeds available time",
                        sourceAgent: .planning,
                        observedAt: now
                    ),
                ],
                confidence: 0.7,
                riskLevel: .medium,
                suggestedActionSummary: "Defer low-priority tasks"
            ),
        ]
    }
}
