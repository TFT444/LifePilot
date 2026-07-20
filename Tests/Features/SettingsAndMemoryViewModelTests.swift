import LifePilotCore
import XCTest
@testable import LifePilotFeatures
@testable import LifePilotServices

@MainActor
final class SettingsAndMemoryViewModelTests: XCTestCase {
    func testAppearanceAndQuietHoursPersist() async throws {
        let store = InMemoryPreferenceStore()
        let viewModel = SettingsViewModel(preferenceStore: store)

        try await viewModel.setAppearance(.dark)
        try await viewModel.setQuietHours(start: 21, end: 6)

        let saved = await store.loadPreferences()
        XCTAssertEqual(saved.appearance, .dark)
        XCTAssertEqual(saved.quietHoursStart, 21)
        XCTAssertEqual(saved.quietHoursEnd, 6)
    }

    func testMemoryFiltersPinnedItems() async throws {
        let store = InMemoryPreferenceStore()
        try await store.saveMemory(
            MemoryItem(
                kind: .place,
                title: "Office",
                isPinned: true,
                provenance: "Explicit user entry"
            )
        )
        try await store.saveMemory(
            MemoryItem(
                kind: .routine,
                title: "School pickup",
                provenance: "Explicit user entry"
            )
        )
        let viewModel = MemoryViewModel(preferenceStore: store)

        await viewModel.load()
        XCTAssertEqual(viewModel.pinnedItems.map(\.title), ["Office"])

        viewModel.setKind(.routine)
        XCTAssertEqual(viewModel.filteredItems.map(\.title), ["School pickup"])
        XCTAssertTrue(viewModel.pinnedItems.isEmpty)
    }
}
