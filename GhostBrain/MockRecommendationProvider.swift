import Foundation
import LifePilotCore

/// A `GhostBrainServing` implementation backed entirely by mock data. This
/// is what the App composition root wires in during Phase 3 — see
/// docs/MASTER_ROADMAP.md's Phase 4 risk mitigation: "screens are built
/// against the Prediction/Recommendation types... even while populated by
/// stub data," so Features never needs to change when GhostBrainService
/// replaces this in Phase 5.
public struct MockRecommendationProvider: GhostBrainServing {
    private let clock: () -> Date

    public init(clock: @escaping () -> Date = Date.init) {
        self.clock = clock
    }

    public func currentModel() async throws -> GhostBrainModel {
        let now = clock()
        return GhostBrainModel(
            generatedAt: now,
            greetingContext: greetingContext(for: now),
            recommendations: Self.sampleRecommendations(relativeTo: now),
            upcomingEvents: Self.sampleEvents(relativeTo: now),
            signals: Self.sampleSignals(relativeTo: now)
        )
    }

    private func greetingContext(for date: Date) -> GhostBrainModel.GreetingContext {
        let hour = Calendar.current.component(.hour, from: date)
        let timeOfDay: GhostBrainModel.GreetingContext.TimeOfDay
        switch hour {
        case 0..<12: timeOfDay = .morning
        case 12..<17: timeOfDay = .afternoon
        default: timeOfDay = .evening
        }
        return GhostBrainModel.GreetingContext(userFirstName: "Alex", timeOfDay: timeOfDay)
    }

    private static func sampleRecommendations(relativeTo now: Date) -> [RecommendationModel] {
        [
            RecommendationModel(
                title: "Leave 15 minutes early for your 10:00 AM",
                reasoning: "Traffic on your usual route is heavier than normal — Maps estimates 22 minutes instead of the usual 12.",
                sourceAgent: .travel,
                riskLevel: .low,
                urgency: .high,
                createdAt: now
            ),
            RecommendationModel(
                title: "Reply to Priya about the Q3 roadmap",
                reasoning: "This email has been waiting three days and mentions a deadline of this Friday.",
                sourceAgent: .email,
                riskLevel: .low,
                urgency: .normal,
                createdAt: now
            ),
            RecommendationModel(
                title: "Reschedule your 2:00 PM — it conflicts with pickup",
                reasoning: "Your calendar shows a 2:00 PM sync overlapping with the recurring 'School Pickup' block.",
                sourceAgent: .calendar,
                riskLevel: .medium,
                urgency: .high,
                createdAt: now
            ),
        ]
    }

    private static func sampleEvents(relativeTo now: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        return [
            CalendarEvent(
                title: "Design Review",
                location: "Studio — Room 2B",
                startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 10, minute: 45, second: 0, of: now) ?? now,
                attendeeCount: 5
            ),
            CalendarEvent(
                title: "1:1 with Priya",
                location: nil,
                startDate: calendar.date(bySettingHour: 13, minute: 30, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now,
                attendeeCount: 2
            ),
            CalendarEvent(
                title: "School Pickup",
                location: "Lincoln Elementary",
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 14, minute: 30, second: 0, of: now) ?? now
            ),
        ]
    }

    private static func sampleSignals(relativeTo now: Date) -> [DaySignal] {
        [
            DaySignal(
                kind: .weather,
                title: "Rain expected this afternoon",
                subtitle: "60% chance starting around 3:00 PM",
                timestamp: now,
                sourceAgent: .calendar
            ),
            DaySignal(
                kind: .finance,
                title: "Unusual charge detected",
                subtitle: "$340 at an unfamiliar merchant",
                timestamp: now,
                sourceAgent: .finance
            ),
        ]
    }
}
