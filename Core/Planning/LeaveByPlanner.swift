import Foundation

/// Builds leave-by briefing findings from travel ETA + optional weather.
public enum LeaveByPlanner: Sendable {
    /// Recommend leaving early enough for travel buffer before `event`.
    public static func finding(
        for event: CalendarEvent,
        travelMinutes: Int,
        weather: WeatherSnapshot?,
        now: Date,
        extraBufferMinutes: Int = 5
    ) -> PlanningFinding? {
        guard travelMinutes > 0 else { return nil }
        let total = travelMinutes + extraBufferMinutes + event.preparationMinutes
        let leaveBy = event.startDate.addingTimeInterval(TimeInterval(-total * 60))
        guard leaveBy > now.addingTimeInterval(-15 * 60) else { return nil }

        var evidence: [EvidenceItem] = [
            EvidenceItem(
                summary: "Travel estimate \(travelMinutes)m"
                    + (event.location.map { " to \($0)" } ?? ""),
                sourceAgent: .travel,
                observedAt: now,
                relatedRecordIDs: [event.id]
            ),
        ]
        if let weather, weather.precipitationChance >= 0.4 {
            evidence.append(
                EvidenceItem(
                    summary: "Precipitation chance "
                        + "\(Int(weather.precipitationChance * 100))%",
                    sourceAgent: .weather,
                    observedAt: weather.asOf,
                    relatedRecordIDs: [event.id]
                )
            )
        }

        let leaveText = leaveBy.formatted(date: .omitted, time: .shortened)
        let risk: RiskLevel = leaveBy.timeIntervalSince(now) < 20 * 60 ? .high : .medium
        return PlanningFinding(
            kind: .insufficientTravelOrPreparation,
            title: "Leave by \(leaveText) for \(event.title)",
            detail: "Allow \(total) minutes including travel and prep.",
            evidence: evidence,
            confidence: 0.8,
            riskLevel: risk,
            suggestedActionSummary: "Leave by \(leaveText)"
        )
    }

    /// Weather-only impact when rain/snow is likely before an outdoor-ish event.
    public static func weatherFinding(
        for event: CalendarEvent,
        weather: WeatherSnapshot,
        now: Date
    ) -> PlanningFinding? {
        guard weather.precipitationChance >= 0.5
            || weather.condition == .rain
            || weather.condition == .storm
            || weather.condition == .snow
        else {
            return nil
        }
        guard event.startDate > now, event.startDate < now.addingTimeInterval(8 * 3600) else {
            return nil
        }
        return PlanningFinding(
            kind: .weatherImpact,
            title: "Weather before \(event.title)",
            detail: "\(weather.condition.rawValue.capitalized), "
                + "\(weather.temperatureFahrenheit)°F — pack accordingly.",
            evidence: [
                EvidenceItem(
                    summary: "Precip \(Int(weather.precipitationChance * 100))%",
                    sourceAgent: .weather,
                    observedAt: weather.asOf,
                    relatedRecordIDs: [event.id]
                ),
            ],
            confidence: 0.75,
            riskLevel: weather.condition == .storm ? .high : .medium,
            suggestedActionSummary: "Check weather before you leave"
        )
    }
}
