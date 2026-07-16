import XCTest
@testable import LifePilotCore
@testable import LifePilotServices

final class SwiftDataStoreTests: XCTestCase {
    func testTaskSurvivesRoundTripInMemoryContainer() async throws {
        let controller = try PersistenceController(inMemory: true)
        let store = SwiftDataTaskStore(container: controller.container)
        let task = TaskItem(title: "Persist me", listID: TaskList.inbox.id)
        try await store.save(task)
        let loaded = await store.allTasks()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.title, "Persist me")
        XCTAssertNil(loaded.first?.dueDate)
    }

    func testPreferencesAndOnboardingPersist() async throws {
        let controller = try PersistenceController(inMemory: true)
        let store = SwiftDataPreferenceStore(container: controller.container)
        var preferences = UserPreferences(onboardingCompleted: true, briefingHour: 6)
        try await store.savePreferences(preferences)
        let reloaded = await store.loadPreferences()
        XCTAssertTrue(reloaded.onboardingCompleted)
        XCTAssertEqual(reloaded.briefingHour, 6)
    }

    func testDeleteAllClearsOwnedData() async throws {
        let controller = try PersistenceController(inMemory: true)
        let tasks = SwiftDataTaskStore(container: controller.container)
        let prefs = SwiftDataPreferenceStore(container: controller.container)
        try await tasks.save(TaskItem(title: "Gone"))
        try await prefs.saveMemory(
            MemoryItem(kind: .preference, title: "Quiet mornings", provenance: "test")
        )
        try await prefs.deleteAllLifePilotData()
        let remainingTasks = await tasks.allTasks()
        let remainingMemory = await prefs.allMemory()
        XCTAssertTrue(remainingTasks.isEmpty)
        XCTAssertTrue(remainingMemory.isEmpty)
    }
}
