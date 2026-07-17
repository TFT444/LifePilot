import Foundation
import LifePilotCore
import SwiftUI

#if canImport(WidgetKit)
import WidgetKit

/// Shared timeline entry for Today / Upcoming home-screen widgets.
public struct LifePilotWidgetEntry: TimelineEntry {
    public let date: Date
    public let greeting: String
    public let headline: String
    public let detail: String

    public init(date: Date, greeting: String, headline: String, detail: String) {
        self.date = date
        self.greeting = greeting
        self.headline = headline
        self.detail = detail
    }
}

/// Builds widget snapshots from Core stores (read-only).
public struct LifePilotWidgetTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in _: Context) -> LifePilotWidgetEntry {
        LifePilotWidgetEntry(
            date: Date(),
            greeting: "Good morning",
            headline: "Prepared for your day",
            detail: "Open LifePilot for leave-by and priorities"
        )
    }

    public func getSnapshot(in _: Context, completion: @escaping (LifePilotWidgetEntry) -> Void) {
        Task {
            completion(await makeEntry())
        }
    }

    public func getTimeline(
        in _: Context,
        completion: @escaping (Timeline<LifePilotWidgetEntry>) -> Void
    ) {
        Task {
            let entry = await makeEntry()
            let next = Date().addingTimeInterval(30 * 60)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func makeEntry() async -> LifePilotWidgetEntry {
        let deps = AppDependencies.live
        let now = Date()
        let tasks = await deps.taskStore.allTasks()
        let open = tasks.filter { !$0.isCompleted }
        let dueToday = open.filter {
            guard let due = $0.dueDate else { return false }
            return Calendar.current.isDateInToday(due)
        }
        let events = await deps.eventStore.allEvents()
            .filter { $0.startDate >= now && $0.status != .declined }
            .sorted { $0.startDate < $1.startDate }
        let nextTitle = events.first?.title ?? dueToday.first?.title ?? "Inbox is clear"
        let hour = Calendar.current.component(.hour, from: now)
        let greeting: String
        switch hour {
        case 5 ..< 12: greeting = "Good morning"
        case 12 ..< 17: greeting = "Good afternoon"
        case 17 ..< 22: greeting = "Good evening"
        default: greeting = "Hello"
        }
        return LifePilotWidgetEntry(
            date: now,
            greeting: greeting,
            headline: nextTitle,
            detail: "\(dueToday.count) due today · \(open.count) open"
        )
    }
}

public struct TodayBriefingWidgetView: View {
    public let entry: LifePilotWidgetEntry

    public init(entry: LifePilotWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LifePilot")
                .font(.caption.weight(.bold))
            Text(entry.greeting)
                .font(.caption2)
            Text(entry.headline)
                .font(.headline)
                .lineLimit(2)
            Text(entry.detail)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }
}

public struct UpcomingAgendaWidgetView: View {
    public let entry: LifePilotWidgetEntry

    public init(entry: LifePilotWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Upcoming")
                .font(.caption.weight(.bold))
            Text(entry.headline)
                .font(.headline)
                .lineLimit(3)
            Text(entry.detail)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }
}

/// Widget configurations. Attach via a Widget Extension target that hosts
/// `@main struct LifePilotWidgetBundle: WidgetBundle`.
public struct TodayBriefingWidget: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.lifepilot.widget.today",
            provider: LifePilotWidgetTimelineProvider()
        ) { entry in
            TodayBriefingWidgetView(entry: entry)
        }
        .configurationDisplayName("Today Briefing")
        .description("Greeting, next commitment, and open-task count.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

public struct UpcomingAgendaWidget: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.lifepilot.widget.upcoming",
            provider: LifePilotWidgetTimelineProvider()
        ) { entry in
            UpcomingAgendaWidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming")
        .description("Next on your LifePilot agenda.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
#endif
