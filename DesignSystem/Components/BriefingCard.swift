import LifePilotCore
import SwiftUI

/// Summarized unit of the Morning Briefing, per docs/DESIGN_SYSTEM.md's
/// Components table. Renders a single recommendation with its source
/// agent, title, and reasoning — the reasoning is always visible, never
/// hidden behind a disclosure, per the Explain principle in
/// README.md's Core Philosophy.
///
/// `BriefingCard` takes plain view data (`Content`) rather than a domain
/// model directly — `DesignSystem` stays reusable independent of any one
/// domain module's types. The owning Feature's ViewModel is responsible
/// for mapping its domain model (e.g. `RecommendationModel` from
/// `LifePilotGhostBrain`) into `Content`. See docs/ARCHITECTURE.md's
/// Dependency Rules: Presentation depends on Domain, never the reverse.
public struct BriefingCard: View {
    private let content: Content

    public init(content: Content) {
        self.content = content
    }

    public var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    AgentAvatar(agent: content.sourceAgent, size: 28)

                    Text(content.sourceAgent.displayName)
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)

                    Spacer()

                    if let badgeText = content.riskBadgeText {
                        SignalBadge(style: .risk, text: badgeText)
                    }
                }

                Text(content.title)
                    .font(.LifePilot.titleMedium)
                    .foregroundStyle(Color.LifePilot.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(content.reasoning)
                    .font(.LifePilot.body)
                    .foregroundStyle(Color.LifePilot.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// Plain view data for `BriefingCard`. Mapped from a domain model
    /// (e.g. `RecommendationModel`) by the owning Feature's ViewModel.
    public struct Content {
        public let title: String
        public let reasoning: String
        public let sourceAgent: AgentKind
        public let riskBadgeText: String?

        public init(title: String, reasoning: String, sourceAgent: AgentKind, riskBadgeText: String? = nil) {
            self.title = title
            self.reasoning = reasoning
            self.sourceAgent = sourceAgent
            self.riskBadgeText = riskBadgeText
        }
    }
}
