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
}
