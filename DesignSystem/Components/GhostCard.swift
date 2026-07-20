import SwiftUI

/// A card representing a single Ghost Brain signal or observation — lighter
/// weight than `BriefingCard`, which is shaped specifically for a full
/// `RecommendationModel` (title, reasoning, risk badge, approve/dismiss
/// affordance). `GhostCard` is for the smaller, ambient things Ghost Brain
/// surfaces along the way — a `DaySignal` like "rain expected this
/// afternoon" — that don't need the full recommendation treatment.
///
/// Visually distinguished by a small animated sparkle mark, so a screen
/// with both `GhostCard`s and ordinary `CardContainer`s makes it clear
/// which content came from Ghost Brain's reasoning versus a plain list.
public struct GhostCard: View {
    private let title: String
    private let subtitle: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    public init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        CardContainer {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkle")
                    .font(.system(size: IconSize.sm, weight: .medium))
                    .foregroundStyle(LinearGradient.LifePilot.accent)
                    .scaleEffect(isPulsing ? 1.1 : 1)
                    .lifePilotAnimation(Motion.loading, reduceMotion: reduceMotion, value: isPulsing)
                    .accessibilityHidden(true)
                    .onAppear { isPulsing = true }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.LifePilot.body.weight(.semibold))
                        .foregroundStyle(Color.LifePilot.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.LifePilot.caption)
                            .foregroundStyle(Color.LifePilot.textSecondary)
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: Spacing.sm) {
        GhostCard(title: "Rain expected this afternoon", subtitle: "60% chance starting around 3:00 PM")
        GhostCard(title: "Tight turnaround detected", subtitle: "Only 10 minutes between events")
    }
    .padding()
}
