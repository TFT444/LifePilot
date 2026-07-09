import XCTest
@testable import LifePilotMocks

final class MockDataTests: XCTestCase {
    func testMockCalendarProducesNonEmptyEvents() {
        XCTAssertFalse(MockCalendar.events().isEmpty)
    }

    func testMockEmailProducesNonEmptyMessages() {
        XCTAssertFalse(MockEmail.messages().isEmpty)
    }

    func testMockTasksProducesNonEmptyItems() {
        XCTAssertFalse(MockTasks.items().isEmpty)
    }

    func testMockTravelProducesNonEmptyItineraries() {
        XCTAssertFalse(MockTravel.itineraries().isEmpty)
    }

    func testMockFinanceProducesNonEmptyTransactions() {
        XCTAssertFalse(MockFinance.transactions().isEmpty)
    }

    func testMockFinanceFlagsAtLeastOneAnomaly() {
        let transactions = MockFinance.transactions()
        XCTAssertTrue(transactions.contains { $0.isAnomalous })
    }

    func testMockNotificationsProducesNonEmptyItems() {
        XCTAssertFalse(MockNotifications.items().isEmpty)
    }

    func testMockWeatherProducesAValidPrecipitationChance() {
        let snapshot = MockWeather.snapshot()
        XCTAssertGreaterThanOrEqual(snapshot.precipitationChance, 0)
        XCTAssertLessThanOrEqual(snapshot.precipitationChance, 1)
    }
}
