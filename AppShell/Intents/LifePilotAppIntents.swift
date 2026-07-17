import AppIntents
import Foundation
import LifePilotCore
import LifePilotServices

/// Siri / Shortcuts: capture an Inbox task without inventing a deadline.
public struct CaptureInboxTaskIntent: AppIntent {
    public static var title: LocalizedStringResource = "Capture LifePilot Task"
    public static var description = IntentDescription(
        "Adds a task to the LifePilot Inbox with no due date."
    )

    @Parameter(title: "Title")
    public var title: String

    public init() {}

    public init(title: String) {
        self.title = title
    }

    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw DomainError.unavailableNamed("Task title is empty")
        }
        let deps = AppDependencies.live
        try await deps.taskStore.save(TaskItem(title: trimmed, listID: TaskList.inbox.id))
        return .result(value: "Captured “\(trimmed)” to Inbox")
    }
}

/// Opens the mental model of the morning briefing via Shortcuts.
public struct RefreshBriefingIntent: AppIntent {
    public static var title: LocalizedStringResource = "Refresh LifePilot Briefing"
    public static var description = IntentDescription(
        "Schedules a background briefing refresh and confirms local stores are ready."
    )

    public init() {}

    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        BriefingBackgroundScheduler.scheduleNext(after: 60)
        let deps = AppDependencies.live
        let tasks = await deps.taskStore.allTasks()
        let open = tasks.filter { !$0.isCompleted }.count
        return .result(value: "Briefing refresh scheduled · \(open) open tasks")
    }
}

public struct LifePilotAppShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: CaptureInboxTaskIntent(),
                phrases: [
                    "Capture a task in \(.applicationName)",
                    "Add an inbox task in \(.applicationName)",
                ],
                shortTitle: "Capture Task",
                systemImageName: "plus.circle"
            ),
            AppShortcut(
                intent: RefreshBriefingIntent(),
                phrases: [
                    "Refresh my \(.applicationName) briefing",
                ],
                shortTitle: "Refresh Briefing",
                systemImageName: "sun.horizon"
            ),
        ]
    }
}
