import SwiftUI

/// A large, prominent card for the single most important piece of content
/// on a screen — the kind of "today at a glance" surface the Morning
/// Briefing's hero moment will need in docs/MASTER_ROADMAP.md Phase 4.
/// Distinct from `CardContainer`: `HeroCard` uses the brand gradient as a
/// background wash and the `lg` corner radius, reserved for genuinely
/// singular moments rather than every card on a screen, per
/// docs/DESIGN_SYSTEM.md's "Calm by default" principle — using `HeroCard`
/// everywhere would make it stop meaning anything.
public struct HeroCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient.LifePilot.accent
                    .opacity(0.14)
            )
            .background(Color.LifePilot.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
            .lifePilotShadow(ShadowStyle.LifePilot.elevated)
    }
}

#Preview {
    HeroCard {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Wednesday, July 9")
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textSecondary)
            Text("Good morning, Alex")
                .font(.LifePilot.titleLarge)
                .foregroundStyle(Color.LifePilot.textPrimary)
        }
    }
    .padding()
}
