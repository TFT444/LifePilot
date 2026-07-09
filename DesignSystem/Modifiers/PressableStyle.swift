import SwiftUI

/// A reusable press interaction for tappable, non-`Button`-backed surfaces
/// (cards that respond to a tap gesture rather than wrapping a `Button`).
/// Extracted from the press-feedback logic already duplicated between
/// `PrimaryButtonStyle` and `SecondaryButtonStyle`, per this PR's Task 3
/// (shared modifiers over duplicated styling).
///
/// `ButtonStyle`-based components (`PrimaryButtonStyle`,
/// `SecondaryButtonStyle`) keep their own `configuration.isPressed`-driven
/// logic — `ButtonStyle` doesn't compose with a plain view modifier the
/// same way — but any new pressable card should use this instead of
/// reimplementing scale/opacity feedback a third time.
public struct PressableStyle: ButtonStyle {
    private let scaleWhenPressed: CGFloat

    public init(scaleWhenPressed: CGFloat = 0.98) {
        self.scaleWhenPressed = scaleWhenPressed
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleWhenPressed : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableStyle {
    /// The default press feedback for tappable cards — a subtle scale and
    /// opacity dip, matching the feel already established by
    /// `PrimaryButtonStyle`/`SecondaryButtonStyle` but usable on any
    /// `Button`-wrapped content, not just text labels.
    public static var lifePilotPressable: PressableStyle { PressableStyle() }
}
