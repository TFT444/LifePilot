import SwiftUI

/// Applies a `ShadowStyle` token with an optional elevated state — used by
/// cards that lift slightly when active or highlighted (`HeroCard`,
/// `GhostCard`), distinct from `CardContainer`'s fixed, always-on shadow.
/// Extracted so "resting vs. elevated shadow" is expressed once rather
/// than reimplemented per component, per this PR's Task 3.
public struct CardElevationModifier: ViewModifier {
    private let isElevated: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(isElevated: Bool) {
        self.isElevated = isElevated
    }

    public func body(content: Content) -> some View {
        content
            .lifePilotShadow(isElevated ? ShadowStyle.LifePilot.elevated : ShadowStyle.LifePilot.card)
            .lifePilotAnimation(Motion.standard, reduceMotion: reduceMotion, value: isElevated)
    }
}

extension View {
    /// Applies the resting or elevated shadow token depending on
    /// `isElevated`, animating between the two (skipped when Reduce
    /// Motion is on).
    public func cardElevation(isElevated: Bool) -> some View {
        modifier(CardElevationModifier(isElevated: isElevated))
    }
}
