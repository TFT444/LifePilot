import XCTest
@testable import LifePilotCore

final class LocationProvidingTests: XCTestCase {
    func testStaticLocationAuthorized() async throws {
        let provider = StaticLocationProvider(
            coordinate: GeoCoordinate(latitude: 40.7, longitude: -74.0)
        )
        let state = await provider.authorizationState()
        XCTAssertEqual(state, .authorized)
        let coord = try await provider.currentCoordinate()
        XCTAssertEqual(coord.latitude, 40.7, accuracy: 0.01)
    }

    func testUnavailableLocationThrows() async {
        let provider = UnavailableLocationProvider()
        do {
            _ = try await provider.currentCoordinate()
            XCTFail("Expected unavailable")
        } catch {
            // expected
        }
    }
}
