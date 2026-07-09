import LifePilotCore

/// The production `GhostBrainServing` implementation. Architecture only in
/// this phase — see docs/MASTER_ROADMAP.md Phase 5 for the real Context,
/// Reasoning, Prediction, and Recommendation engines this type will
/// eventually orchestrate.
///
/// `GhostBrainService` is intentionally not used by `Features` yet; the App
/// composition root wires `MockRecommendationProvider` in its place until
/// Phase 5 lands. It exists now so the seam is established and reviewable
/// ahead of the real implementation.
public struct GhostBrainService: GhostBrainServing {
    public init() {}

    public func currentModel() async throws -> GhostBrainModel {
        throw DomainError.unavailable(
            "GhostBrainService has no reasoning engine yet — see docs/MASTER_ROADMAP.md Phase 5. Use MockRecommendationProvider during Phase 3."
        )
    }
}
