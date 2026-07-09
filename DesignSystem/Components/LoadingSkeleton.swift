import SwiftUI

/// A shimmering placeholder shape for content that hasn't loaded yet.
/// Fills a genuine gap: `HomeView` and `TimelineView` both load
/// asynchronously via `.task` with no loading state today — content
/// simply pops in once `viewModel.load()` completes. `LoadingSkeleton`
/// gives future call sites a real "loading" state to show instead of a
/// blank screen.
///
/// The shimmer respects Reduce Motion: with it enabled, the skeleton
/// renders as a static, evenly-opaque shape instead of animating.
public struct LoadingSkeleton: View {
    private let cornerRadius: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    public init(cornerRadius: CGFloat = CornerRadius.sm) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.LifePilot.textSecondary.opacity(shimmerOpacity))
            .lifePilotAnimation(Motion.loading, reduceMotion: reduceMotion, value: isAnimating)
            .onAppear { isAnimating = true }
            .accessibilityHidden(true)
    }

    private var shimmerOpacity: Double {
        guard !reduceMotion else { return 0.16 }
        return isAnimating ? 0.22 : 0.12
    }
}

/// A ready-made skeleton matching `CardContainer`'s shape, for screens
/// that want a full loading-card placeholder rather than composing
/// `LoadingSkeleton` shapes by hand.
public struct LoadingCardSkeleton: View {
    public init() {}

    public var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                LoadingSkeleton()
                    .frame(width: 120, height: 12)
                LoadingSkeleton()
                    .frame(height: 20)
                LoadingSkeleton()
                    .frame(height: 16)
                    .frame(maxWidth: 200)
            }
        }
        .accessibilityLabel("Loading")
    }
}

#Preview {
    VStack(spacing: Spacing.sm) {
        LoadingCardSkeleton()
        LoadingCardSkeleton()
    }
    .padding()
}
