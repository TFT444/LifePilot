import XCTest
@testable import LifePilotCore

final class PersistenceMigrationTests: XCTestCase {
    func testFreshInstallMigratesToCurrent() throws {
        let migrator = PersistenceMigrator()
        let version = try migrator.migrate(from: 0)
        XCTAssertEqual(version, PersistenceSchema.currentVersion)
    }

    func testAlreadyCurrentIsNoOp() throws {
        let migrator = PersistenceMigrator()
        let version = try migrator.migrate(from: PersistenceSchema.currentVersion)
        XCTAssertEqual(version, PersistenceSchema.currentVersion)
    }

    func testFutureSchemaRejected() {
        let migrator = PersistenceMigrator()
        XCTAssertThrowsError(try migrator.migrate(from: 99))
    }
}

final class AppRouteTests: XCTestCase {
    func testResolvesCorePaths() {
        XCTAssertEqual(AppRoute.resolve(pathComponents: ["tasks", "today"]), .tasks(filter: .today))
        XCTAssertEqual(AppRoute.resolve(pathComponents: ["approvals"]), .approvals)
        XCTAssertEqual(AppRoute.resolve(pathComponents: ["capture", "event"]), .quickCapture(.event))
        XCTAssertNil(AppRoute.resolve(pathComponents: ["unknown"]))
    }

    func testMissingEntityFailsSoft() {
        let router = AppRouter()
        let id = UUID()
        let result = router.resolveTarget(.task(id), tasks: [], events: [])
        XCTAssertEqual(result, .missing("Task not found"))
    }
}

final class LaunchStateTests: XCTestCase {
    func testFreshInstallShowsOnboarding() {
        XCTAssertTrue(LaunchState().shouldShowOnboarding)
    }

    func testCompletedCurrentVersionSkipsOnboarding() {
        let state = LaunchState(
            hasCompletedOnboarding: true,
            onboardingVersion: LaunchState.currentOnboardingVersion
        )
        XCTAssertFalse(state.shouldShowOnboarding)
    }

    func testMaterialOnboardingUpgradeShowsAgain() {
        let state = LaunchState(hasCompletedOnboarding: true, onboardingVersion: 0)
        XCTAssertTrue(state.shouldShowOnboarding)
    }
}

final class LoadableStateTests: XCTestCase {
    func testValueExtraction() {
        let loaded: LoadableState<[Int]> = .loaded([1, 2])
        XCTAssertEqual(loaded.value, [1, 2])
        let empty: LoadableState<[Int]> = .empty
        XCTAssertNil(empty.value)
        let offline: LoadableState<[Int]> = .offline(cached: [9])
        XCTAssertEqual(offline.value, [9])
    }
}

final class IntegrationProtocolTests: XCTestCase {
    func testDeniedCalendarThrowsUnavailable() async {
        let calendar = UnavailableCalendarIntegration()
        let state = await calendar.authorizationState()
        XCTAssertEqual(state, .denied)
        do {
            _ = try await calendar.fetchEvents(from: Date(), to: Date())
            XCTFail("Expected unavailable")
        } catch is DomainError {
            // expected
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testCloudSyncDisabledByDefault() async {
        let sync = DisabledCloudSyncIntegration()
        await XCTAssertFalse(sync.isSyncEnabled())
    }
}
