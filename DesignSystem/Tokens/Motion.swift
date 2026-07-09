import SwiftUI

/// Motion tokens per docs/DESIGN_SYSTEM.md's Motion principle: "Default
/// transitions are short (150–250ms) and use standard easing; anything
/// longer needs a specific justification tied to what it's communicating."
public enum Motion {
    /// The default transition for most UI state changes — card appearance,
    /// selection state, sheet content changes.
    public static let standard = Animation.easeInOut(duration: 0.2)

    /// A faster transition for micro-interactions: button press feedback,
    /// toggle states.
    public static let quick = Animation.easeOut(duration: 0.15)

    /// A slower, more deliberate transition reserved for full-screen
    /// changes (onboarding steps, tab switches) where the extra duration
    /// communicates a bigger context shift.
    public static let deliberate = Animation.easeInOut(duration: 0.35)

    /// A springy transition for content that should feel alive when it
    /// appears — new cards, approved actions. Used more sparingly than
    /// `standard`, since spring motion carries more visual weight.
    public static let spring = Animation.spring(response: 0.4, dampingFraction: 0.75)

    /// The press-down feedback used by `PrimaryButtonStyle` and
    /// `SecondaryButtonStyle` — quick enough to feel responsive to touch.
    public static let press = Animation.easeOut(duration: 0.12)

    /// A continuous, repeating animation for loading states
    /// (`LoadingSkeleton`). Reduce Motion turns the shimmer into a static
    /// state instead of looping indefinitely — see
    /// `View.lifePilotAnimation(_:reduceMotion:value:)`.
    public static let loading = Animation.easeInOut(duration: 1.1).repeatForever(autoreverses: true)
}

extension View {
    /// Applies `animation` unless Reduce Motion is enabled, in which case
    /// the state change happens instantly. Read
    /// `@Environment(\.accessibilityReduceMotion)` in the calling view and
    /// pass it through, per docs/ENGINEERING_GUIDE.md's Accessibility
    /// standard. Every component that plays a decorative or continuous
    /// animation (as opposed to a state-change transition the user
    /// directly initiated) should route through this rather than applying
    /// `Animation` unconditionally.
    public func lifePilotAnimation(
        _ animation: Animation,
        reduceMotion: Bool,
        value: some Equatable
    ) -> some View {
        self.animation(reduceMotion ? nil : animation, value: value)
    }
}
