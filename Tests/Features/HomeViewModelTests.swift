import LifePilotCore
import LifePilotGhostBrain
import XCTest
@testable import LifePilotFeatures

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testLoadPopulatesGreetingAndRecommendations() async {
        let viewModel = HomeViewModel(ghostBrain: MockRecommendationProvider())

        await viewModel.load()

        XCTAssertFalse(viewModel.greeting.isEmpty)
        XCTAssertFalse(viewModel.recommendations.isEmpty)
        XCTAssertFalse(viewModel.upcomingEvents.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadHandlesFailingProviderGracefully() async {
        struct FailingProvider: GhostBrainServing {
            func currentModel() async throws -> GhostBrainModel {
                throw DomainError.unavailable("test failure")
            }
        }

        let viewModel = HomeViewModel(ghostBrain: FailingProvider())

        await viewModel.load()

        XCTAssertTrue(viewModel.recommendations.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }
}
