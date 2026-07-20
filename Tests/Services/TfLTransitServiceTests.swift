import Foundation
import XCTest
@testable import LifePilotServices
@testable import LifePilotCore

final class TfLTransitServiceTests: XCTestCase {
    // Sample payloads matching the real TfL Unified API response shapes.
    private let arrivalsJSON = """
    [
      {"id":"1","lineName":"Central","destinationName":"Epping Underground Station","towards":"Epping","platformName":"Eastbound - Platform 2","timeToStation":240},
      {"id":"2","lineName":"Victoria","destinationName":"Brixton Underground Station","towards":"Brixton","platformName":"Southbound - Platform 5","timeToStation":60}
    ]
    """.data(using: .utf8)!

    private let statusJSON = """
    [
      {"name":"Bakerloo","lineStatuses":[{"statusSeverityDescription":"Good Service"}]},
      {"name":"Circle","lineStatuses":[{"statusSeverityDescription":"Severe Delays"}]}
    ]
    """.data(using: .utf8)!

    func testDecodeDeparturesSortsAndCleansNames() throws {
        let departures = try TfLTransitService.decodeDepartures(from: arrivalsJSON)
        XCTAssertEqual(departures.count, 2)
        // Sorted soonest-first: Victoria (60s) before Central (240s).
        XCTAssertEqual(departures.first?.lineName, "Victoria")
        XCTAssertEqual(departures.first?.destination, "Brixton") // " Underground Station" stripped
        XCTAssertEqual(departures.first?.etaLabel, "1 min")
        XCTAssertEqual(departures.last?.destination, "Epping")
    }

    func testDecodeLineStatusesClassifiesSeverity() throws {
        let statuses = try TfLTransitService.decodeLineStatuses(from: statusJSON)
        XCTAssertEqual(statuses.count, 2)
        XCTAssertEqual(statuses.first?.lineName, "Bakerloo")
        XCTAssertEqual(statuses.first?.severity, .good)
        XCTAssertEqual(statuses.last?.severity, .severe)
    }

    func testURLIncludesAppKeyWhenProvided() {
        let service = TfLTransitService(appKey: "SECRET") { _ in Data() }
        let url = service.url(path: "/Line/Mode/tube/Status")
        XCTAssertTrue(url.absoluteString.contains("app_key=SECRET"), url.absoluteString)
    }

    func testURLOmitsAppKeyWhenAbsent() {
        let service = TfLTransitService { _ in Data() }
        let url = service.url(path: "/Line/Mode/tube/Status")
        XCTAssertFalse(url.absoluteString.contains("app_key"))
    }

    func testDeparturesUsesInjectedFetch() async throws {
        let data = arrivalsJSON
        let service = TfLTransitService { _ in data }
        let departures = try await service.departures(at: "940GZZLUOXC")
        XCTAssertEqual(departures.first?.lineName, "Victoria")
    }

    func testLineStatusesUsesInjectedFetch() async throws {
        let data = statusJSON
        let service = TfLTransitService { _ in data }
        let statuses = try await service.lineStatuses()
        XCTAssertEqual(statuses.count, 2)
    }
}
