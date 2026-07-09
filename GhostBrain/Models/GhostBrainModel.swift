import Foundation
import LifePilotCore

/// Ghost Brain's fused understanding of "today" — the single model every
/// screen in `Features` ultimately renders from. This is the `DayModel`
/// referenced in docs/ARCHITECTURE.md's AI Agent Architecture diagram.
///
/// This phase populates `GhostBrainModel` from `MockRecommendationProvider`
/// only. Real fusion logic across live agent signals arrives in
/// docs/MASTER_ROADMAP.md Phase 5.
public struct GhostBrainModel: Sendable {
    public let generatedAt: Date
    public let greetingContext: GreetingContext
    public let recommendations: [RecommendationModel]
    public let upcomingEvents: [CalendarEvent]
    public let signals: [DaySignal]

    public init(
        generatedAt: Date,
        greetingContext: GreetingContext,
        recommendations: [RecommendationModel],
        upcomingEvents: [CalendarEvent],
        signals: [DaySignal]
    ) {
        self.generatedAt = generatedAt
        self.greetingContext = greetingContext
        self.recommendations = recommendations
        self.upcomingEvents = upcomingEvents
        self.signals = signals
    }

    /// Recommendations ranked by urgency, highest first — the order the
    /// Approvals queue and Home screen should present them in.
    public var rankedRecommendations: [RecommendationModel] {
        recommendations.sorted { $0.urgency > $1.urgency }
    }

    /// Contextual information used to personalize the Home screen's
    /// greeting, kept separate from raw signals since it's derived, not
    /// observed.
    public struct GreetingContext: Sendable {
        public let userFirstName: String
        public let timeOfDay: TimeOfDay

        public init(userFirstName: String, timeOfDay: TimeOfDay) {
            self.userFirstName = userFirstName
            self.timeOfDay = timeOfDay
        }

        public enum TimeOfDay: String, Sendable {
            case morning
            case afternoon
            case evening

            public var greetingWord: String {
                switch self {
                case .morning: return "Good morning"
                case .afternoon: return "Good afternoon"
                case .evening: return "Good evening"
                }
            }
        }
    }
}
