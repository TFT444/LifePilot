import SwiftUI

/// Shadow tokens for elevated surfaces. Kept subtle by design, per
/// docs/DESIGN_SYSTEM.md's "Calm by default" principle — LifePilot should
/// never feel like it's shouting, including through heavy drop shadows.
public struct ShadowStyle {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

    public enum LifePilot {
        public static let card = ShadowStyle(
            color: Color.black.opacity(0.12),
            radius: 12,
            x: 0,
            y: 4
        )

        public static let elevated = ShadowStyle(
            color: Color.black.opacity(0.18),
            radius: 24,
            x: 0,
            y: 8
        )
    }
}

extension View {
    /// Applies a `ShadowStyle` token, e.g. `.lifePilotShadow(ShadowStyle.LifePilot.card)`.
    public func lifePilotShadow(_ style: ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
