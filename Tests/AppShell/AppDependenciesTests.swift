import XCTest
@testable import LifePilotAppShell
@testable import LifePilotServices

final class AppDependenciesTests: XCTestCase {
    func testLiveDependenciesWireSwiftDataStores() async {
        let dependencies = AppDependencies.live
        XCTAssertNotNil(dependencies.taskStore)
        XCTAssertNotNil(dependencies.eventStore)
        XCTAssertNotNil(dependencies.preferenceStore)
        XCTAssertNotNil(dependencies.approvalStore)
        XCTAssertTrue(dependencies.notificationScheduler is UserNotificationsScheduler)
        XCTAssertTrue(dependencies.calendarIntegration is EventKitCalendarIntegration)
    }

    func testPreviewDependenciesUseInMemoryStores() async throws {
        let dependencies = AppDependencies.preview
        let tasks = await dependencies.taskStore.allTasks()
        XCTAssertFalse(tasks.isEmpty)
    }

    func testLiveGhostBrainIsDeterministicUnavailable() async {
        let dependencies = AppDependencies.live
        do {
            _ = try await dependencies.ghostBrain.currentModel()
            XCTFail("GhostBrainService should stay unavailable; use planning engine")
        } catch {
            // expected
        }
    }
}
