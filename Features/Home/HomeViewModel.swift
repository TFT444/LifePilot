import Foundation
import LifePilotCore
import LifePilotDesignSystem
import LifePilotGhostBrain

/// Owns the Home screen's state, sourcing it from `GhostBrainServing`. Per
/// docs/ENGINEERING_GUIDE.md's MVVM pattern, the View never talks to
/// `GhostBrain` directly — only through this ViewModel.
@Observable
@MainActor
public final class HomeViewModel {
    public private(set) var greeting: String = ""
    public private(set) var dateText: String = ""
    public private(set) var recommendations: [BriefingCard.Content] = []
    public private(set) var upcomingEvents: [CalendarEvent] = []
    public private(set) var isLoading = false

    private let ghostBrain: GhostBrainServing

    public init(ghostBrain: GhostBrainServing) {
        self.ghostBrain = ghostBrain
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }

        guard let model = try? await ghostBrain.currentModel() else {
            return
        }

        greeting = "\(model.greetingContext.timeOfDay.greetingWord), \(model.greetingContext.userFirstName)"
        dateText = model.generatedAt.formatted(.dateTime.weekday(.wide).month(.wide).day())
        upcomingEvents = model.upcomingEvents

        recommendations = model.rankedRecommendations.map { recommendation in
            BriefingCard.Content(
                title: recommendation.title,
                reasoning: recommendation.reasoning,
                sourceAgent: recommendation.sourceAgent,
                riskBadgeText: recommendation.riskLevel == .low ? nil : recommendation.riskLevel.rawValue.capitalized
            )
        }
    }
}
