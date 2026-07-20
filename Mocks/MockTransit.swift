import Foundation
import LifePilotCore

/// Realistic sample transit data for previews, tests, and offline fallback,
/// mirroring the shape of the TfL Unified API once normalised.
public enum MockTransit {
    public static func departures() -> [TransitDeparture] {
        [
            TransitDeparture(lineName: "Victoria", destination: "Brixton", platform: "Southbound · Plat 5", secondsToStation: 60),
            TransitDeparture(lineName: "Central", destination: "Epping", platform: "Eastbound · Plat 2", secondsToStation: 150),
            TransitDeparture(lineName: "Bakerloo", destination: "Elephant & Castle", platform: "Southbound · Plat 3", secondsToStation: 240),
            TransitDeparture(lineName: "Victoria", destination: "Walthamstow Central", platform: "Northbound · Plat 6", secondsToStation: 360),
        ]
    }

    public static func lineStatuses() -> [TransitLineStatus] {
        [
            TransitLineStatus(lineName: "Bakerloo", statusDescription: "Good Service", severity: .good),
            TransitLineStatus(lineName: "Central", statusDescription: "Minor Delays", severity: .minor),
            TransitLineStatus(lineName: "Circle", statusDescription: "Severe Delays", severity: .severe),
            TransitLineStatus(lineName: "Victoria", statusDescription: "Good Service", severity: .good),
        ]
    }
}

/// A `TransitProviding` test double / preview provider returning `MockTransit`
/// data, so `Features` previews and unit tests don't need the network.
public struct MockTransitProvider: TransitProviding {
    public init() {}

    public func departures(at stopId: String) async throws -> [TransitDeparture] {
        MockTransit.departures()
    }

    public func lineStatuses() async throws -> [TransitLineStatus] {
        MockTransit.lineStatuses()
    }
}
