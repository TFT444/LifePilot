import Foundation
import LifePilotCore

/// Deterministic sample briefing content for previews and offline demos.
/// No finance, shopping, or health signals.
public struct MockRecommendationProvider: GhostBrainServing {
    private let clock: @Sendable () -> Date

    public init(clock: @escaping @Sendable () -> Date = Date.init) {
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
        let timeOfDay: GreetingTimeOfDay
        switch hour {
        case 0 ..< 12: timeOfDay = .morning
        case 12 ..< 17: timeOfDay = .afternoon
        default: timeOfDay = .evening
        }
        return GhostBrainModel.GreetingContext(userFirstName: "Alex", timeOfDay: timeOfDay)
    }

    private static func sampleRecommendations(relativeTo now: Date) -> [RecommendationModel] {
        [
            RecommendationModel(
                title: "Leave 15 minutes early for your 10:00 AM",
                reasoning: "Traffic on your usual route is heavier than normal — "
                    + "Maps estimates 22 minutes instead of the usual 12.",
                sourceAgent: .travel,
                riskLevel: .low,
                urgency: .high,
                createdAt: now
            ),
            RecommendationModel(
                title: "Block 45 minutes for the board deck",
                reasoning: "High-priority task is due this afternoon and you still have "
                    + "an open focus window after lunch.",
                sourceAgent: .task,
                riskLevel: .low,
                urgency: .normal,
                createdAt: now
            ),
            RecommendationModel(
                title: "Reschedule your 2:00 PM — it conflicts with pickup",
                reasoning: "Your calendar shows a 2:00 PM sync overlapping with the recurring School Pickup block.",
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
                attendeeCount: 5,
                context: .work,
                eventKind: .meeting
            ),
            CalendarEvent(
                title: "1:1 with Priya",
                location: nil,
                startDate: calendar.date(bySettingHour: 13, minute: 30, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now,
                attendeeCount: 2,
                context: .work,
                eventKind: .meeting
            ),
            CalendarEvent(
                title: "School Pickup",
                location: "Lincoln Elementary",
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 14, minute: 30, second: 0, of: now) ?? now,
                context: .personal,
                eventKind: .personal,
                preparationMinutes: 10,
                travelBufferMinutes: 15
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
                sourceAgent: .weather,
                freshness: .cached
            ),
            DaySignal(
                kind: .conflict,
                title: "Pickup overlaps 2:00 PM sync",
                subtitle: "Calendar conflict detected",
                timestamp: now,
                sourceAgent: .planning,
                freshness: .live
            ),
        ]
    }
}
