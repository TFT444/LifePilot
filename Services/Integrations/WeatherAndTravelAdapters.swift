import Foundation
import LifePilotCore
import MapKit

#if canImport(WeatherKit)
import WeatherKit
#endif

/// Optional WeatherKit adapter. Graceful when unavailable; never blocks briefing.
/// Production needs a resolved CLLocation (Settings → Location); until then
/// callers fall back to leave-by without weather context.
public struct WeatherKitIntegration: WeatherIntegrating {
    private let fallback: WeatherSnapshot?

    public init(fallback: WeatherSnapshot? = nil) {
        self.fallback = fallback
    }

    public func authorizationState() async -> CapabilityState {
        #if canImport(WeatherKit)
        .notDetermined
        #else
        .unavailable
        #endif
    }

    public func currentWeather() async throws -> WeatherSnapshot {
        if let fallback {
            return fallback
        }
        throw DomainError.unavailableNamed(
            "WeatherKit needs an explicit location; briefing continues without weather"
        )
    }
}

/// MapKit ETA estimates. Never books or purchases anything.
public struct MapKitTravelTimeIntegration: TravelTimeIntegrating {
    public init() {}

    public func authorizationState() async -> CapabilityState {
        .notDetermined
    }

    public func travelTimeMinutes(
        from origin: String,
        to destination: String,
        departingAt _: Date
    ) async throws -> Int {
        let originItem = try await mapItem(for: origin)
        let destinationItem = try await mapItem(for: destination)

        let request = MKDirections.Request()
        request.source = originItem
        request.destination = destinationItem
        request.transportType = .automobile

        let response = try await MKDirections(request: request).calculate()
        guard let route = response.routes.first else {
            throw DomainError.unavailableNamed("No route found")
        }
        return max(1, Int(route.expectedTravelTime / 60))
    }

    private func mapItem(for query: String) async throws -> MKMapItem {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let response = try await MKLocalSearch(request: request).start()
        guard let item = response.mapItems.first else {
            throw DomainError.unavailableNamed("Place not found: \(query)")
        }
        return item
    }
}
