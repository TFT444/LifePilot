import CoreGraphics

/// Spacing tokens matching docs/DESIGN_SYSTEM.md's Spacing section exactly:
/// an 8pt base grid. Components compose from these rather than introducing
/// one-off values.
public enum Spacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
}
