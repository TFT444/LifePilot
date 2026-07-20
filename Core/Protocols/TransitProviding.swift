import Foundation

/// The interface the Travel Agent / Features depend on to obtain live transit
/// data. Real provider adapters (e.g. `TfLTransitService` in `LifePilotServices`)
/// and test doubles both conform to this, so no consumer code changes when the
/// backing provider does — see docs/ARCHITECTURE.md's Dependency Rules, and the
/// Travel integration in docs/MASTER_ROADMAP.md Phase 7.
public protocol TransitProviding: Sendable {
    /// Live upcoming departures at a stop, identified by the provider's stop
    /// id (e.g. a TfL NaPTAN id like `940GZZLUOXC`), soonest first.
    func departures(at stopId: String) async throws -> [TransitDeparture]

    /// Current status for every line on the default network (e.g. all Tube
    /// lines).
    func lineStatuses() async throws -> [TransitLineStatus]
}
