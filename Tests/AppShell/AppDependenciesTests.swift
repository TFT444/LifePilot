import XCTest
@testable import LifePilotAppShell

final class AppDependenciesTests: XCTestCase {
    func testLiveDependenciesProvideAWorkingGhostBrain() async throws {
        let dependencies = AppDependencies.live

        let model = try await dependencies.ghostBrain.currentModel()

        XCTAssertFalse(model.recommendations.isEmpty)
    }
}
