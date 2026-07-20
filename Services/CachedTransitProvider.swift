import Foundation
import LifePilotCore

public protocol TransitSnapshotCaching: Sendable {
    func load(key: String) async -> TransitSnapshot?
    func save(_ snapshot: TransitSnapshot, key: String) async
}

/// Adds persistent last-known fallback without hiding that cached data is stale.
public actor CachedTransitProvider: TransitProviding {
    private let upstream: any TransitProviding
    private let cache: any TransitSnapshotCaching
    private let clock: any ClockProviding
    private let sourceName: String

    public init(
        upstream: any TransitProviding,
        cache: any TransitSnapshotCaching = UserDefaultsTransitSnapshotCache(),
        clock: any ClockProviding = SystemClock(),
        sourceName: String = "TfL Open Data"
    ) {
        self.upstream = upstream
        self.cache = cache
        self.clock = clock
        self.sourceName = sourceName
    }

    public func departures(at stopId: String) async throws -> [TransitDeparture] {
        try await upstream.departures(at: stopId)
    }

    public func lineStatuses() async throws -> [TransitLineStatus] {
        try await upstream.lineStatuses()
    }

    public func snapshot(at stopId: String, lines: [String]) async throws -> TransitSnapshot {
        let key = Self.cacheKey(stopId: stopId, lines: lines)
        do {
            try Task.checkCancellation()
            async let departures = upstream.departures(at: stopId)
            async let statuses = upstream.lineStatuses()
            let (loadedDepartures, loadedStatuses) = try await (departures, statuses)
            try Task.checkCancellation()
            let snapshot = TransitSnapshot(
                departures: Array(loadedDepartures.prefix(8)),
                lineStatuses: Self.filter(loadedStatuses, lines: lines),
                fetchedAt: clock.now(),
                sourceName: sourceName
            )
            await cache.save(snapshot, key: key)
            return snapshot
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if var cached = await cache.load(key: key) {
                cached.isStale = true
                cached.errorMessage = error.localizedDescription
                return cached
            }
            throw error
        }
    }

    private static func filter(
        _ statuses: [TransitLineStatus],
        lines: [String]
    ) -> [TransitLineStatus] {
        let selected = Set(lines.map { $0.lowercased() })
        return statuses.filter { selected.isEmpty || selected.contains($0.lineName.lowercased()) }
    }

    private static func cacheKey(stopId: String, lines: [String]) -> String {
        ([stopId] + lines.map { $0.lowercased() }.sorted()).joined(separator: "|")
    }
}

public actor UserDefaultsTransitSnapshotCache: TransitSnapshotCaching {
    private let defaults: UserDefaults
    private let keyPrefix = "lifepilot.transit."

    public init(suiteName: String? = nil) {
        if let suiteName, let suite = UserDefaults(suiteName: suiteName) {
            defaults = suite
        } else {
            defaults = .standard
        }
    }

    public func load(key: String) async -> TransitSnapshot? {
        guard let data = defaults.data(forKey: storageKey(key)) else { return nil }
        return try? JSONDecoder().decode(TransitSnapshot.self, from: data)
    }

    public func save(_ snapshot: TransitSnapshot, key: String) async {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: storageKey(key))
    }

    private func storageKey(_ key: String) -> String {
        keyPrefix + Data(key.utf8).base64EncodedString()
    }
}
