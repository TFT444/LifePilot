import Foundation

/// Least-privilege location access for weather / leave-by only.
public protocol LocationProviding: Sendable {
    func authorizationState() async -> CapabilityState
    func requestAuthorization() async -> CapabilityState
    func currentCoordinate() async throws -> GeoCoordinate
}

public struct GeoCoordinate: Hashable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct UnavailableLocationProvider: LocationProviding {
    public init() {}

    public func authorizationState() async -> CapabilityState {
        .unavailable
    }

    public func requestAuthorization() async -> CapabilityState {
        .unavailable
    }

    public func currentCoordinate() async throws -> GeoCoordinate {
        throw DomainError.unavailableNamed("Location is unavailable in this build")
    }
}

/// Fixed coordinate for previews and deterministic leave-by / weather tests.
public struct StaticLocationProvider: LocationProviding {
    private let coordinate: GeoCoordinate

    public init(coordinate: GeoCoordinate = GeoCoordinate(latitude: 51.5074, longitude: -0.1278)) {
        self.coordinate = coordinate
    }

    public func authorizationState() async -> CapabilityState {
        .authorized
    }

    public func requestAuthorization() async -> CapabilityState {
        .authorized
    }

    public func currentCoordinate() async throws -> GeoCoordinate {
        coordinate
    }
}
