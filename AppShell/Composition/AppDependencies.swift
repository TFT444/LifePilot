import LifePilotGhostBrain

/// The composition root: wires concrete implementations to the protocols
/// `Features` depend on, per docs/ENGINEERING_GUIDE.md's Dependency
/// Injection standard: "A lightweight composition root in App/ wires
/// concrete implementations to their protocols at app launch."
///
/// In this phase, `ghostBrain` is always `MockRecommendationProvider` —
/// swapping in the real `GhostBrainService` (docs/MASTER_ROADMAP.md Phase
/// 5) is a one-line change here, with no change required in `Features`.
public struct AppDependencies: Sendable {
    public let ghostBrain: GhostBrainServing

    public init(ghostBrain: GhostBrainServing = MockRecommendationProvider()) {
        self.ghostBrain = ghostBrain
    }

    /// The default, production-shaped set of dependencies for this phase.
    public static let live = AppDependencies()
}
