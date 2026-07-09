import SwiftUI

/// The background-and-corner-radius treatment shared by every elevated
/// surface in LifePilot. `CardContainer` composes this with padding and a
/// shadow; components that need the surface without `CardContainer`'s
/// fixed padding (e.g. a full-bleed `HeroCard` background) can apply it
/// directly. Extracted per this PR's Task 3 so the pairing of
/// `Color.LifePilot.backgroundElevated` + `CornerRadius.md` exists in one
/// place, not reimplemented per component.
public struct SurfaceModifier: ViewModifier {
    private let cornerRadius: CGFloat
    private let fill: Color

    public init(cornerRadius: CGFloat = CornerRadius.md, fill: Color = Color.LifePilot.backgroundElevated) {
        self.cornerRadius = cornerRadius
        self.fill = fill
    }

    public func body(content: Content) -> some View {
        content
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    /// Applies the standard elevated-surface background and corner radius,
    /// without padding or shadow — compose with `.padding(...)` and
    /// `.lifePilotShadow(...)` directly, or use `CardContainer` for the
    /// common all-in-one case.
    public func lifePilotSurface(
        cornerRadius: CGFloat = CornerRadius.md,
        fill: Color = Color.LifePilot.backgroundElevated
    ) -> some View {
        modifier(SurfaceModifier(cornerRadius: cornerRadius, fill: fill))
    }
}
