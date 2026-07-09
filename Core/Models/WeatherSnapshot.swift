import Foundation

/// A point-in-time weather reading for the user's current or upcoming
/// location. Backed by WeatherKit in a later phase — see
/// docs/MASTER_ROADMAP.md Phase 7.
public struct WeatherSnapshot: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let condition: Condition
    public let temperatureFahrenheit: Int
    public let highFahrenheit: Int
    public let lowFahrenheit: Int
    public let precipitationChance: Double
    public let asOf: Date

    public init(
        id: UUID = UUID(),
        condition: Condition,
        temperatureFahrenheit: Int,
        highFahrenheit: Int,
        lowFahrenheit: Int,
        precipitationChance: Double,
        asOf: Date
    ) {
        self.id = id
        self.condition = condition
        self.temperatureFahrenheit = temperatureFahrenheit
        self.highFahrenheit = highFahrenheit
        self.lowFahrenheit = lowFahrenheit
        self.precipitationChance = precipitationChance
        self.asOf = asOf
    }

    public enum Condition: String, Sendable {
        case clear
        case cloudy
        case rain
        case snow
        case storm

        /// The SF Symbol representing this condition in the UI.
        public var symbolName: String {
            switch self {
            case .clear: return "sun.max.fill"
            case .cloudy: return "cloud.fill"
            case .rain: return "cloud.rain.fill"
            case .snow: return "cloud.snow.fill"
            case .storm: return "cloud.bolt.rain.fill"
            }
        }
    }
}
