import Foundation

/// A single travel segment (flight, train, etc.) the Travel Agent tracks
/// for delays and rebooking opportunities.
public struct TravelItinerary: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let carrier: String
    public let identifier: String
    public let origin: String
    public let destination: String
    public let departureDate: Date
    public let arrivalDate: Date
    public let status: Status

    public init(
        id: UUID = UUID(),
        carrier: String,
        identifier: String,
        origin: String,
        destination: String,
        departureDate: Date,
        arrivalDate: Date,
        status: Status = .onTime
    ) {
        self.id = id
        self.carrier = carrier
        self.identifier = identifier
        self.origin = origin
        self.destination = destination
        self.departureDate = departureDate
        self.arrivalDate = arrivalDate
        self.status = status
    }

    public enum Status: String, Sendable {
        case onTime
        case delayed
        case cancelled
        case boarding
    }
}
