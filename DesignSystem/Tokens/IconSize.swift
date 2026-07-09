import CoreGraphics

/// Icon glyph sizes, for SF Symbol point sizes used outside running text.
/// Distinct from `Font.LifePilot` — these size standalone iconography
/// (empty states, splash marks, onboarding illustrations), not typography.
public enum IconSize {
    /// Small inline icons: list rows, buttons.
    public static let sm: CGFloat = 20

    /// Section and empty-state icons.
    public static let md: CGFloat = 22

    /// Onboarding step icons.
    public static let lg: CGFloat = 44

    /// Hero-scale marks: splash, empty full-screen states.
    public static let xl: CGFloat = 56
}
