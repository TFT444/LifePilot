import Foundation

/// A single upcoming departure at a transit stop, normalised from a provider
/// feed (e.g. the TfL Unified API) into the shape the Travel Agent reasons
/// over. Providers are adapters; this Domain type is the source of truth for
/// meaning, per docs/ARCHITECTURE.md's Dependency Rules.
public struct TransitDeparture: Identifiable, Hashable, Sendable, Codable {
    public let id: String
    public let lineName: String
    public let destination: String
    public let platform: String?
    /// Seconds until the vehicle reaches this stop, as reported by the feed.
    public let secondsToStation: Int

    public init(
        id: String = UUID().uuidString,
        lineName: String,
        destination: String,
        platform: String? = nil,
        secondsToStation: Int
    ) {
        self.id = id
        self.lineName = lineName
        self.destination = destination
        self.platform = platform
        self.secondsToStation = max(0, secondsToStation)
    }

    /// Whole minutes until departure (rounded up), for display.
    public var minutesToDeparture: Int {
        Int((Double(secondsToStation) / 60).rounded(.up))
    }

    /// A short display label: "Due" when imminent, else "N min".
    public var etaLabel: String {
        secondsToStation < 30 ? "Due" : "\(minutesToDeparture) min"
    }
}
