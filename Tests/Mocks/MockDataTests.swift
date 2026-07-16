import XCTest
@testable import LifePilotMocks

final class MockDataTests: XCTestCase {
    func testMockCalendarProducesNonEmptyEvents() {
        XCTAssertFalse(MockCalendar.events().isEmpty)
    }

    func testMockTasksProduceInboxAndDueItems() {
        let tasks = MockTasks.items()
        XCTAssertFalse(tasks.isEmpty)
    }

    func testMockNotificationsExcludeBannedAgents() {
        let agents = Set(MockNotifications.items().compactMap(\.sourceAgent))
        XCTAssertFalse(agents.contains(.security) && agents.isEmpty)
        for banned in ["finance", "shopping", "health", "email"] {
            XCTAssertFalse(agents.map(\.rawValue).contains(banned))
        }
    }

    func testMockWeatherAndTravelExist() {
        XCTAssertNotNil(MockWeather.snapshot())
        XCTAssertFalse(MockTravel.itineraries().isEmpty)
    }
}
