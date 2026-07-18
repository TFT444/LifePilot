import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Offline search across LifePilot-owned tasks and events.
public struct SearchView: View {
    @State private var viewModel: SearchViewModel

    public init(taskStore: any TaskStore, eventStore: any EventStore) {
        _viewModel = State(
            initialValue: SearchViewModel(taskStore: taskStore, eventStore: eventStore)
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            TextField("Search tasks and events", text: $viewModel.query)
                .textFieldStyle(.roundedBorder)
                .padding(Spacing.lg)
                .onChange(of: viewModel.query) { _, _ in
                    Task { await viewModel.search() }
                }

            if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                EmptyStateView(
                    symbolName: "magnifyingglass",
                    message: "Search locally saved tasks and events. Works offline."
                )
                .padding(Spacing.lg)
                Spacer()
            } else if viewModel.results.isEmpty {
                EmptyStateView(
                    symbolName: "magnifyingglass",
                    message: "No matches in your local LifePilot data."
                )
                .padding(Spacing.lg)
                Spacer()
            } else {
                List(viewModel.results) { result in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.title)
                            .font(.LifePilot.body)
                        Text(result.subtitle)
                            .font(.LifePilot.caption)
                            .foregroundStyle(Color.LifePilot.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                }
                .listStyle(.plain)
            }
        }
        .background(Color.LifePilot.backgroundPrimary)
        .navigationTitle("Search")
        .task { await viewModel.search() }
    }
}

@Observable
@MainActor
public final class SearchViewModel {
    public struct Result: Identifiable, Hashable, Sendable {
        public let id: UUID
        public var title: String
        public var subtitle: String
    }

    public var query = ""
    public private(set) var results: [Result] = []

    private let taskStore: any TaskStore
    private let eventStore: any EventStore

    public init(taskStore: any TaskStore, eventStore: any EventStore) {
        self.taskStore = taskStore
        self.eventStore = eventStore
    }

    public func search() async {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else {
            results = []
            return
        }
        let tasks = await taskStore.allTasks()
        let events = await eventStore.allEvents()
        var matched: [Result] = []
        for task in tasks where task.title.lowercased().contains(needle)
            || (task.notes?.lowercased().contains(needle) ?? false)
            || task.tags.contains(where: { $0.lowercased().contains(needle) })
        {
            matched.append(
                Result(
                    id: task.id,
                    title: task.title,
                    subtitle: task.dueDate.map {
                        "Task · \($0.formatted(date: .abbreviated, time: .shortened))"
                    } ?? "Task · Inbox"
                )
            )
        }
        for event in events where event.title.lowercased().contains(needle)
            || (event.location?.lowercased().contains(needle) ?? false)
            || (event.notes?.lowercased().contains(needle) ?? false)
        {
            matched.append(
                Result(
                    id: event.id,
                    title: event.title,
                    subtitle: "Event · \(event.startDate.formatted(date: .abbreviated, time: .shortened))"
                )
            )
        }
        results = matched.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}
