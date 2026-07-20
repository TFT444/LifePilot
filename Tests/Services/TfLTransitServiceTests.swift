import Foundation
import XCTest
@testable import LifePilotCore
@testable import LifePilotServices

final class TfLTransitServiceTests: XCTestCase {
    /// Sample payloads matching the real TfL Unified API response shapes.
    private let arrivalsJSON = Data("""
    [
      {
        "id": "1", "lineName": "Central",
        "destinationName": "Epping Underground Station",
        "towards": "Epping", "platformName": "Eastbound - Platform 2",
        "timeToStation": 240
      },
      {
        "id": "2", "lineName": "Victoria",
        "destinationName": "Brixton Underground Station",
        "towards": "Brixton", "platformName": "Southbound - Platform 5",
        "timeToStation": 60
      }
    ]
    """.utf8)

    private let statusJSON = Data("""
    [
      { "name": "Bakerloo", "lineStatuses": [{ "statusSeverityDescription": "Good Service" }] },
      { "name": "Circle", "lineStatuses": [{ "statusSeverityDescription": "Severe Delays" }] }
    ]
    """.utf8)

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
        let payload = arrivalsJSON
        let service = TfLTransitService { _ in payload }
        let departures = try await service.departures(at: "940GZZLUOXC")
        XCTAssertEqual(departures.first?.lineName, "Victoria")
    }

    func testLineStatusesUsesInjectedFetch() async throws {
        let payload = statusJSON
        let service = TfLTransitService { _ in payload }
        let statuses = try await service.lineStatuses()
        XCTAssertEqual(statuses.count, 2)
    }

    func testMalformedResponseThrowsDecodingError() {
        XCTAssertThrowsError(try TfLTransitService.decodeDepartures(from: Data("not-json".utf8)))
    }

    func testCachedProviderReturnsFreshFilteredSnapshotAndCachesEmptyData() async throws {
        let cache = MemoryTransitCache()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let provider = TransitStub(
            departures: [],
            statuses: [
                TransitLineStatus(
                    lineName: "Victoria",
                    statusDescription: "Good Service",
                    severity: .good
                ),
                TransitLineStatus(
                    lineName: "Central",
                    statusDescription: "Minor Delays",
                    severity: .minor
                ),
            ]
        )
        let cached = CachedTransitProvider(
            upstream: provider,
            cache: cache,
            clock: FixedClock(now)
        )

        let snapshot = try await cached.snapshot(
            at: "940GZZLUOXC",
            lines: ["Victoria"]
        )

        XCTAssertTrue(snapshot.departures.isEmpty)
        XCTAssertEqual(snapshot.lineStatuses.map(\.lineName), ["Victoria"])
        XCTAssertEqual(snapshot.fetchedAt, now)
        XCTAssertFalse(snapshot.isStale)
        let cacheCount = await cache.count()
        XCTAssertEqual(cacheCount, 1)
    }

    func testNetworkFailureReturnsExplicitlyStaleLastKnownData() async throws {
        let cache = MemoryTransitCache()
        let fresh = CachedTransitProvider(
            upstream: TransitStub(departures: [.sample], statuses: []),
            cache: cache,
            clock: FixedClock(Date(timeIntervalSince1970: 1_700_000_000))
        )
        _ = try await fresh.snapshot(at: "STOP", lines: [])
        let offline = CachedTransitProvider(
            upstream: TransitStub(error: URLError(.notConnectedToInternet)),
            cache: cache
        )

        let fallback = try await offline.snapshot(at: "STOP", lines: [])

        XCTAssertTrue(fallback.isStale)
        XCTAssertEqual(fallback.departures, [.sample])
        XCTAssertNotNil(fallback.errorMessage)
    }

    func testHTTPFailureWithoutCacheIsVisible() async {
        let provider = CachedTransitProvider(
            upstream: TransitStub(
                error: DomainError.unavailableNamed("TfL request failed: HTTP 429")
            ),
            cache: MemoryTransitCache()
        )

        do {
            _ = try await provider.snapshot(at: "STOP", lines: [])
            XCTFail("Expected HTTP failure")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("HTTP 429"))
        }
    }

    func testDecodingFailureFallsBackToLastKnownSnapshot() async throws {
        let cache = MemoryTransitCache()
        let fresh = CachedTransitProvider(
            upstream: TransitStub(departures: [.sample], statuses: []),
            cache: cache
        )
        _ = try await fresh.snapshot(at: "STOP", lines: [])
        let malformed = TfLTransitService { _ in Data("not-json".utf8) }
        let provider = CachedTransitProvider(upstream: malformed, cache: cache)

        let fallback = try await provider.snapshot(at: "STOP", lines: [])

        XCTAssertTrue(fallback.isStale)
        XCTAssertEqual(fallback.departures, [.sample])
    }

    func testCancellationNeverReturnsCachedData() async throws {
        let cache = MemoryTransitCache()
        let fresh = CachedTransitProvider(
            upstream: TransitStub(departures: [.sample], statuses: []),
            cache: cache
        )
        _ = try await fresh.snapshot(at: "STOP", lines: [])
        let cancelled = CachedTransitProvider(
            upstream: TransitStub(error: CancellationError()),
            cache: cache
        )

        do {
            _ = try await cancelled.snapshot(at: "STOP", lines: [])
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected: cancellation must not be disguised as cached success.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private struct TransitStub: TransitProviding {
    let departureValues: [TransitDeparture]
    let statusValues: [TransitLineStatus]
    let error: (any Error & Sendable)?

    init(
        departures: [TransitDeparture] = [],
        statuses: [TransitLineStatus] = [],
        error: (any Error & Sendable)? = nil
    ) {
        departureValues = departures
        statusValues = statuses
        self.error = error
    }

    func departures(at _: String) async throws -> [TransitDeparture] {
        if let error { throw error }
        return departureValues
    }

    func lineStatuses() async throws -> [TransitLineStatus] {
        if let error { throw error }
        return statusValues
    }
}

private actor MemoryTransitCache: TransitSnapshotCaching {
    private var values: [String: TransitSnapshot] = [:]

    func load(key: String) async -> TransitSnapshot? {
        values[key]
    }

    func save(_ snapshot: TransitSnapshot, key: String) async {
        values[key] = snapshot
    }

    func count() -> Int {
        values.count
    }
}

private extension TransitDeparture {
    static let sample = TransitDeparture(
        id: "sample",
        lineName: "Victoria",
        destination: "Brixton",
        secondsToStation: 60
    )
}
