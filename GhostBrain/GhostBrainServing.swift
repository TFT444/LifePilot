import LifePilotCore

/// The single interface `Features` depends on to obtain Ghost Brain's
/// current understanding of the day. Real fusion logic (docs/MASTER_ROADMAP.md
/// Phase 5) and this phase's mock-backed implementation both conform to the
/// same protocol, so no `Features` code changes when the real engine lands —
/// see docs/ARCHITECTURE.md's Dependency Rules, point 5.
public protocol GhostBrainServing: Sendable {
    /// Produces the current `GhostBrainModel` for the day. Never throws in
    /// this phase's mock implementation, but the signature allows a future
    /// implementation to fail gracefully (e.g. all upstream agents
    /// unreachable) without a breaking API change.
    func currentModel() async throws -> GhostBrainModel
}
