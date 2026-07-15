import LifePilotCore
import XCTest
@testable import LifePilotServices

final class InMemoryStoreTests: XCTestCase {
    func testTaskStoreRoundTrip() async throws {
        let store = InMemoryTaskStore()
        let task = TaskItem(title: "Test task", priority: .high)
        try await store.save(task)
        let all = await store.allTasks()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.title, "Test task")
    }

    func testPreferenceExportAndWipe() async throws {
        let store = InMemoryPreferenceStore()
        var prefs = await store.loadPreferences()
        prefs.onboardingCompleted = true
        try await store.savePreferences(prefs)
        try await store.saveMemory(MemoryItem(kind: .place, title: "School", provenance: "user"))
        let data = try await store.exportAll()
        XCTAssertFalse(data.isEmpty)
        try await store.deleteAllLifePilotData()
        let after = await store.loadPreferences()
        XCTAssertFalse(after.onboardingCompleted)
        let memory = await store.allMemory()
        XCTAssertTrue(memory.isEmpty)
    }

    func testStoreBackedTimelineMergesEventsAndTasks() async throws {
        let now = Date()
        let tasks = InMemoryTaskStore(seed: [
            TaskItem(title: "Due soon", dueDate: now.addingTimeInterval(600)),
        ])
        let events = InMemoryEventStore(seed: [
            CalendarEvent(title: "Meeting", startDate: now, endDate: now.addingTimeInterval(1800)),
        ])
        let provider = StoreBackedTimelineProvider(taskStore: tasks, eventStore: events)
        let entries = await provider.loadEntries(relativeTo: now)
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(Set(entries.map(\.kind)), Set([.event, .task]))
    }
}
