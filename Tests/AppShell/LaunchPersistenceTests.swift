import LifePilotCore
import XCTest
@testable import LifePilotAppShell
@testable import LifePilotServices

final class LaunchPersistenceTests: XCTestCase {
    func testReturningUserSkipsOnboarding() async {
        let preferences = InMemoryPreferenceStore(
            preferences: UserPreferences(onboardingCompleted: true)
        )
        let store = PreferenceBackedLaunchStore(preferenceStore: preferences)
        let state = await store.load()
        XCTAssertFalse(state.shouldShowOnboarding)
    }

    func testResetOnboardingShowsAgain() async throws {
        let preferences = InMemoryPreferenceStore(
            preferences: UserPreferences(onboardingCompleted: true)
        )
        let store = PreferenceBackedLaunchStore(preferenceStore: preferences)
        try await store.resetOnboarding()
        let state = await store.load()
        XCTAssertTrue(state.shouldShowOnboarding)
    }
}
