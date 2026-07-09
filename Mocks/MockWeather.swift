import Foundation
import LifePilotCore

/// Realistic sample weather data for previews, tests, and Phase 3's
/// mock-driven screens. Not used by production code — see
/// docs/MASTER_ROADMAP.md Phase 7 for the real WeatherKit-backed source.
public enum MockWeather {
    public static func snapshot(relativeTo now: Date = Date()) -> WeatherSnapshot {
        WeatherSnapshot(
            condition: .cloudy,
            temperatureFahrenheit: 64,
            highFahrenheit: 68,
            lowFahrenheit: 54,
            precipitationChance: 0.6,
            asOf: now
        )
    }
}
