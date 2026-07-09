import Foundation
import LifePilotCore

/// Realistic sample travel itinerary data for previews, tests, and Phase
/// 3's mock-driven screens.
public enum MockTravel {
    public static func itineraries(relativeTo now: Date = Date()) -> [TravelItinerary] {
        [
            TravelItinerary(
                carrier: "United",
                identifier: "UA 1472",
                origin: "SFO",
                destination: "JFK",
                departureDate: now.addingTimeInterval(2 * 24 * 3600),
                arrivalDate: now.addingTimeInterval(2 * 24 * 3600 + 5 * 3600),
                status: .delayed
            ),
            TravelItinerary(
                carrier: "Amtrak",
                identifier: "Acela 2151",
                origin: "New York Penn",
                destination: "Boston South",
                departureDate: now.addingTimeInterval(9 * 24 * 3600),
                arrivalDate: now.addingTimeInterval(9 * 24 * 3600 + 4 * 3600),
                status: .onTime
            ),
        ]
    }
}
