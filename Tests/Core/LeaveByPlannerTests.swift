import Foundation
import XCTest
@testable import LifePilotCore

final class LeaveByPlannerTests: XCTestCase {
    func testLeaveByFindingUsesTravelMinutes() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let event = CalendarEvent(
            title: "Client visit",
            location: "Office",
            startDate: now.addingTimeInterval(3600),
            endDate: now.addingTimeInterval(5400)
        )
        let finding = LeaveByPlanner.finding(
            for: event,
            travelMinutes: 20,
            weather: nil,
            now: now
        )
        XCTAssertNotNil(finding)
        XCTAssertTrue(finding?.title.contains("Leave by") == true)
        XCTAssertEqual(finding?.evidence.first?.sourceAgent, .travel)
    }

    func testWeatherFindingWhenRainLikely() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let event = CalendarEvent(
            title: "School pickup",
            startDate: now.addingTimeInterval(7200),
            endDate: now.addingTimeInterval(7800)
        )
        let weather = WeatherSnapshot(
            condition: .rain,
            temperatureFahrenheit: 55,
            highFahrenheit: 58,
            lowFahrenheit: 48,
            precipitationChance: 0.7,
            asOf: now
        )
        let finding = LeaveByPlanner.weatherFinding(for: event, weather: weather, now: now)
        XCTAssertEqual(finding?.kind, .weatherImpact)
    }
}
