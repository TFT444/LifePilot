import SwiftUI

/// A horizontal divider that draws itself in when it first appears,
/// rather than popping in at full width. Purely decorative — used
/// between sections on content-dense screens where a plain `Divider()`
/// would be visually abrupt. Respects Reduce Motion: the line simply
/// appears at full width immediately when it's enabled.
public struct AnimatedDivider: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRevealed = false

    public init() {}

    public var body: some View {
        Rectangle()
            .fill(Color.LifePilot.textSecondary.opacity(0.16))
            .frame(height: 1)
            .scaleEffect(x: isRevealed || reduceMotion ? 1 : 0, anchor: .leading)
            .lifePilotAnimation(Motion.deliberate, reduceMotion: reduceMotion, value: isRevealed)
            .onAppear { isRevealed = true }
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        Text("Section One")
        AnimatedDivider()
        Text("Section Two")
    }
    .padding()
}
