import SwiftUI

/// A translucent, blurred surface treatment for chrome that should feel
/// layered above content — tab bars, navigation backgrounds, floating
/// action sheets. Used sparingly, per docs/DESIGN_SYSTEM.md's "Calm by
/// default" principle: glass communicates depth for genuinely floating
/// chrome, not as a decorative default for ordinary cards (use
/// `CardContainer` for those).
public struct GlassSurface<Content: View>: View {
    private let cornerRadius: CGFloat
    private let content: Content

    public init(cornerRadius: CGFloat = 0, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .modifier(GlassModifier(cornerRadius: cornerRadius))
    }
}

/// The reusable glass-chrome treatment `GlassSurface` and
/// `.lifePilotGlass()` both apply — extracted per this PR's Task 3 so the
/// `.ultraThinMaterial` background is defined once.
public struct GlassModifier: ViewModifier {
    private let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = 0) {
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        if cornerRadius > 0 {
            content
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            content
                .background(.ultraThinMaterial)
        }
    }
}

extension View {
    /// Applies the standard glass chrome background used for floating
    /// surfaces like tab bars and sheets. Pass `cornerRadius` to also clip
    /// to a rounded shape — e.g. a floating card rather than a full-bleed
    /// bar.
    public func lifePilotGlass(cornerRadius: CGFloat = 0) -> some View {
        modifier(GlassModifier(cornerRadius: cornerRadius))
    }
}
