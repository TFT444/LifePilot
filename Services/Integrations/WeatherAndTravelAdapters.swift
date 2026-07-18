import Foundation
import LifePilotCore
import MapKit

#if canImport(CoreLocation)
import CoreLocation
#endif

#if canImport(WeatherKit)
import WeatherKit
#endif

/// WeatherKit adapter. Uses `LocationProviding` when authorized; never blocks briefing.
public struct WeatherKitIntegration: WeatherIntegrating {
    private let locationProvider: any LocationProviding
    private let fallback: WeatherSnapshot?

    public init(
        locationProvider: any LocationProviding = UnavailableLocationProvider(),
        fallback: WeatherSnapshot? = nil
    ) {
        self.locationProvider = locationProvider
        self.fallback = fallback
    }

    public func authorizationState() async -> CapabilityState {
        await locationProvider.authorizationState()
    }

    public func currentWeather() async throws -> WeatherSnapshot {
        if let coord = try? await locationProvider.currentCoordinate() {
            #if canImport(WeatherKit) && canImport(CoreLocation)
            do {
                return try await fetchWeatherKit(at: coord)
            } catch {
                if let fallback { return fallback }
                throw error
            }
            #else
            if let fallback { return fallback }
            throw DomainError.unavailableNamed("WeatherKit unavailable on this platform")
            #endif
        }
        if let fallback { return fallback }
        throw DomainError.unavailableNamed(
            "Location needed for weather; briefing continues without it"
        )
    }

    #if canImport(WeatherKit) && canImport(CoreLocation)
    private func fetchWeatherKit(at coord: GeoCoordinate) async throws -> WeatherSnapshot {
        let service = WeatherService.shared
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        let weather = try await service.weather(for: location)
        let current = weather.currentWeather
        let day = weather.dailyForecast.first
        return WeatherSnapshot(
            condition: Self.mapCondition(String(describing: current.condition)),
            temperatureFahrenheit: Int(
                current.temperature.converted(to: .fahrenheit).value.rounded()
            ),
            highFahrenheit: Int(
                day?.highTemperature.converted(to: .fahrenheit).value.rounded() ?? 0
            ),
            lowFahrenheit: Int(
                day?.lowTemperature.converted(to: .fahrenheit).value.rounded() ?? 0
            ),
            precipitationChance: day?.precipitationChance ?? 0,
            asOf: current.date
        )
    }

    private static func mapCondition(_ raw: String) -> WeatherSnapshot.Condition {
        let value = raw.lowercased()
        if value.contains("thunder") || value.contains("storm") || value.contains("hurricane") {
            return .storm
        }
        if value.contains("snow") || value.contains("sleet") || value.contains("blizzard") {
            return .snow
        }
        if value.contains("rain") || value.contains("drizzle") {
            return .rain
        }
        if value.contains("clear") || value.contains("hot") || value.contains("sun") {
            return .clear
        }
        return .cloudy
    }
    #endif
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
        if query.localizedCaseInsensitiveCompare("Current Location") == .orderedSame {
            return MKMapItem.forCurrentLocation()
        }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let response = try await MKLocalSearch(request: request).start()
        guard let item = response.mapItems.first else {
            throw DomainError.unavailableNamed("Place not found: \(query)")
        }
        return item
    }
}
