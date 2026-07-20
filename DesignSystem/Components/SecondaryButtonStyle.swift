import SwiftUI

/// A lower-emphasis button style for secondary actions — dismiss, cancel,
/// "not now." Uses a flat elevated background rather than the brand
/// gradient, keeping the gradient reserved for primary actions.
public struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.LifePilot.body.weight(.medium))
            .foregroundStyle(Color.LifePilot.textPrimary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm + Spacing.xs)
            .frame(maxWidth: .infinity)
            .background(Color.LifePilot.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(reduceMotion ? nil : Motion.quick, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    public static var lifePilotSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
