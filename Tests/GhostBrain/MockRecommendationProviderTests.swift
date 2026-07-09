import Foundation
import LifePilotCore
import XCTest
@testable import LifePilotGhostBrain

final class MockRecommendationProviderTests: XCTestCase {
    func testCurrentModelReturnsRecommendations() async throws {
        let provider = MockRecommendationProvider()

        let model = try await provider.currentModel()

        XCTAssertFalse(model.recommendations.isEmpty)
        XCTAssertFalse(model.upcomingEvents.isEmpty)
    }

    func testRankedRecommendationsAreSortedByUrgencyDescending() async throws {
        let provider = MockRecommendationProvider()

        let model = try await provider.currentModel()
        let urgencies = model.rankedRecommendations.map(\.urgency)

        XCTAssertEqual(urgencies, urgencies.sorted(by: >))
    }

    func testGreetingContextMatchesInjectedClock() async throws {
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 9
        components.hour = 8
        let morning = Calendar.current.date(from: components) ?? Date()

        let provider = MockRecommendationProvider(clock: { morning })

        let model = try await provider.currentModel()

        XCTAssertEqual(model.greetingContext.timeOfDay, .morning)
    }

    func testGhostBrainServiceThrowsUntilPhase5() async {
        let service = GhostBrainService()

        do {
            _ = try await service.currentModel()
            XCTFail("Expected GhostBrainService to throw until Phase 5's reasoning engine lands")
        } catch {
            XCTAssertTrue(error is DomainError)
        }
    }
}
