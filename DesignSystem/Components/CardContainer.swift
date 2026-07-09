import SwiftUI

/// The shared elevated-surface treatment every card-style component in
/// LifePilot builds from — `BriefingCard`, `TimelineRow`, and similar,
/// per docs/DESIGN_SYSTEM.md's Components table. Centralizing this here
/// means every card gets consistent background, radius, padding, and
/// shadow without each feature reimplementing it.
public struct CardContainer<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(Spacing.md)
            .lifePilotSurface()
            .lifePilotShadow(ShadowStyle.LifePilot.card)
    }
}
