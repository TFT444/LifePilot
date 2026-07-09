import CoreGraphics

/// Corner radius tokens, following the same scale philosophy as `Spacing`.
/// Not yet formalized in docs/DESIGN_SYSTEM.md — introduced here to satisfy
/// Phase 3's component needs; the design system doc should be updated in
/// the same PR if these values change.
public enum CornerRadius {
    /// Small controls: badges, chips.
    public static let sm: CGFloat = 8

    /// Standard cards and buttons.
    public static let md: CGFloat = 16

    /// Prominent surfaces: sheets, hero cards.
    public static let lg: CGFloat = 24

    /// Fully rounded — pills and circular avatars.
    public static let full: CGFloat = 999
}
