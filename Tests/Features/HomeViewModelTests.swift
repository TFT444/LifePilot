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

    func testLoadSurfacesTransitAndCreatesAttributedDisruptionFinding() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = TransitSnapshot(
            departures: [
                TransitDeparture(
                    id: "departure",
                    lineName: "Victoria",
                    destination: "Brixton",
                    secondsToStation: 120
                ),
            ],
            lineStatuses: [
                TransitLineStatus(
                    lineName: "Victoria",
                    statusDescription: "Severe Delays",
                    severity: .severe
                ),
            ],
            fetchedAt: now,
            sourceName: "TfL Open Data"
        )
        let preferences = UserPreferences(
            transitStopID: "940GZZLUOXC",
            transitStopName: "Oxford Circus",
            transitLineNames: ["Victoria"]
        )
        let viewModel = HomeViewModel(
            taskStore: InMemoryTaskStore(),
            eventStore: InMemoryEventStore(),
            preferenceStore: InMemoryPreferenceStore(preferences: preferences),
            integrations: HomeBriefingIntegrations(
                transit: HomeTransitProvider(snapshot: snapshot)
            ),
            clock: FixedClock(now)
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.transitDepartures.map(\.destination), ["Brixton"])
        XCTAssertEqual(viewModel.transitSource, "TfL Open Data")
        XCTAssertTrue(viewModel.freshnessSummary.contains("Transit live"))
        let finding = viewModel.findings.first { $0.title.contains("Victoria disruption") }
        XCTAssertEqual(finding?.evidence.first?.sourceAgent, .travel)
        XCTAssertEqual(finding?.evidence.first?.freshness, .live)
    }

    func testTransitFailureDoesNotBlockLocalBriefing() async {
        let preferences = UserPreferences(transitStopID: "STOP")
        let viewModel = HomeViewModel(
            taskStore: InMemoryTaskStore(seed: [TaskItem(title: "Local task")]),
            eventStore: InMemoryEventStore(),
            preferenceStore: InMemoryPreferenceStore(preferences: preferences),
            integrations: HomeBriefingIntegrations(
                transit: HomeTransitProvider(errorMessage: "Offline")
            )
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.topTasks.map(\.title), ["Local task"])
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.freshnessSummary.contains("Transit unavailable"))
    }
}

private struct HomeTransitProvider: TransitProviding {
    var snapshotValue: TransitSnapshot?
    var errorMessage: String?

    init(snapshot: TransitSnapshot? = nil, errorMessage: String? = nil) {
        snapshotValue = snapshot
        self.errorMessage = errorMessage
    }

    func departures(at _: String) async throws -> [TransitDeparture] {
        if let errorMessage { throw DomainError.unavailableNamed(errorMessage) }
        return snapshotValue?.departures ?? []
    }

    func lineStatuses() async throws -> [TransitLineStatus] {
        if let errorMessage { throw DomainError.unavailableNamed(errorMessage) }
        return snapshotValue?.lineStatuses ?? []
    }

    func snapshot(at _: String, lines _: [String]) async throws -> TransitSnapshot {
        if let errorMessage { throw DomainError.unavailableNamed(errorMessage) }
        return snapshotValue ?? TransitSnapshot(
            departures: [],
            lineStatuses: [],
            fetchedAt: Date(),
            sourceName: "Test"
        )
    }
}
