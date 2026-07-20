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

    /// One coherent response for feature UIs. Implementations may override
    /// this to add persistent caching and stale-data recovery.
    func snapshot(at stopId: String, lines: [String]) async throws -> TransitSnapshot
}

public extension TransitProviding {
    func snapshot(at stopId: String, lines: [String]) async throws -> TransitSnapshot {
        async let departures = departures(at: stopId)
        async let statuses = lineStatuses()
        let (loadedDepartures, loadedStatuses) = try await (departures, statuses)
        let selectedLines = Set(lines.map { $0.lowercased() })
        let filtered = loadedStatuses.filter { status in
            selectedLines.isEmpty || selectedLines.contains(status.lineName.lowercased())
        }
        return TransitSnapshot(
            departures: loadedDepartures,
            lineStatuses: filtered,
            fetchedAt: Date(),
            sourceName: "Transit provider"
        )
    }
}

public struct UnavailableTransitProvider: TransitProviding {
    public init() {}

    public func departures(at _: String) async throws -> [TransitDeparture] {
        throw DomainError.unavailableNamed("Transit data is unavailable in this build.")
    }

    public func lineStatuses() async throws -> [TransitLineStatus] {
        throw DomainError.unavailableNamed("Transit data is unavailable in this build.")
    }
}
