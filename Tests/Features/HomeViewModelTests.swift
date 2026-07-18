import LifePilotCore
import XCTest
@testable import LifePilotFeatures
@testable import LifePilotServices

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testLoadUsesStoresAndPlanningFindings() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let taskStore = InMemoryTaskStore(seed: [
            TaskItem(title: "Ship brief", dueDate: now.addingTimeInterval(-600)),
        ])
        let eventStore = InMemoryEventStore(seed: [
            CalendarEvent(
                title: "Standup",
                startDate: now.addingTimeInterval(3600),
                endDate: now.addingTimeInterval(5400),
                context: .work,
                eventKind: .meeting
            ),
            CalendarEvent(
                title: "Overlap",
                startDate: now.addingTimeInterval(4000),
                endDate: now.addingTimeInterval(7200),
                context: .work,
                eventKind: .meeting
            ),
        ])
        let preferences = InMemoryPreferenceStore()
        let viewModel = HomeViewModel(
            taskStore: taskStore,
            eventStore: eventStore,
            preferenceStore: preferences,
            clock: FixedClock(now)
        )

        await viewModel.load()

        XCTAssertFalse(viewModel.greeting.isEmpty)
        XCTAssertFalse(viewModel.topTasks.isEmpty)
        XCTAssertFalse(viewModel.upcomingEvents.isEmpty)
        XCTAssertFalse(viewModel.recommendations.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadSurvivesDeniedCalendar() async {
        let viewModel = HomeViewModel(
            taskStore: InMemoryTaskStore(),
            eventStore: InMemoryEventStore(),
            preferenceStore: InMemoryPreferenceStore(),
            integrations: HomeBriefingIntegrations(
                calendar: UnavailableCalendarIntegration()
            )
        )

        await viewModel.load()

        XCTAssertTrue(viewModel.freshnessSummary.contains("Calendar") || viewModel.freshnessSummary.contains("Local"))
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadIncludesWeatherAndLeaveBy() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let eventStore = InMemoryEventStore(seed: [
            CalendarEvent(
                title: "Office",
                location: "Downtown",
                startDate: now.addingTimeInterval(7200),
                endDate: now.addingTimeInterval(9000),
                travelBufferMinutes: 25
            ),
        ])
        let weather = WeatherSnapshot(
            condition: .rain,
            temperatureFahrenheit: 60,
            highFahrenheit: 64,
            lowFahrenheit: 52,
            precipitationChance: 0.6,
            asOf: now
        )
        let viewModel = HomeViewModel(
            taskStore: InMemoryTaskStore(),
            eventStore: eventStore,
            preferenceStore: InMemoryPreferenceStore(),
            integrations: HomeBriefingIntegrations(
                weather: StaticWeatherIntegration(snapshot: weather),
                travel: StaticTravelTimeIntegration(minutes: 22)
            ),
            clock: FixedClock(now)
        )

        await viewModel.load()

        XCTAssertNotNil(viewModel.weatherSummary)
        XCTAssertNotNil(viewModel.leaveBySummary)
        XCTAssertTrue(viewModel.freshnessSummary.contains("Weather"))
    }
}
