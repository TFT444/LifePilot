import SwiftUI

/// A translucent, blurred surface treatment for chrome that should feel
/// layered above content — tab bars, navigation backgrounds, floating
/// action sheets. Used sparingly, per docs/DESIGN_SYSTEM.md's "Calm by
/// default" principle: glass communicates depth for genuinely floating
/// chrome, not as a decorative default for ordinary cards (use
/// `CardContainer` for those).
public struct GlassSurface<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .background(.ultraThinMaterial)
    }
}

extension View {
    /// Applies the standard glass chrome background used for floating
    /// surfaces like tab bars and sheets.
    public func lifePilotGlass() -> some View {
        background(.ultraThinMaterial)
    }
}
