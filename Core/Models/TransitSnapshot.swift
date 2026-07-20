import Foundation

/// Provider-neutral transit data with visible provenance and freshness.
public struct TransitSnapshot: Hashable, Sendable, Codable {
    public var departures: [TransitDeparture]
    public var lineStatuses: [TransitLineStatus]
    public var fetchedAt: Date
    public var isStale: Bool
    public var sourceName: String
    public var errorMessage: String?

    public init(
        departures: [TransitDeparture],
        lineStatuses: [TransitLineStatus],
        fetchedAt: Date,
        isStale: Bool = false,
        sourceName: String,
        errorMessage: String? = nil
    ) {
        self.departures = departures
        self.lineStatuses = lineStatuses
        self.fetchedAt = fetchedAt
        self.isStale = isStale
        self.sourceName = sourceName
        self.errorMessage = errorMessage
    }

    public var disruptions: [TransitLineStatus] {
        lineStatuses.filter { !$0.isGoodService }
    }
}
