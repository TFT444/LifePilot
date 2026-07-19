import SwiftUI

/// The primary call-to-action button style, rendering the brand gradient.
/// Reserve for the single most important action on a screen — pairing this
/// with `SecondaryButtonStyle` for everything else keeps the gradient
/// meaningful rather than decorative, per docs/DESIGN_SYSTEM.md's "Calm by
/// default" principle.
public struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.LifePilot.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm + Spacing.xs)
            .frame(maxWidth: .infinity)
            .background(LinearGradient.LifePilot.accent)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(reduceMotion ? nil : Motion.quick, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    public static var lifePilotPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
