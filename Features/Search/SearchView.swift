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
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.LifePilot.textSecondary)
                TextField("Search tasks and events", text: $viewModel.query)
            }
                .lifePilotField()
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
                List {
                    ForEach(SearchResultKind.allCases, id: \.self) { kind in
                        let matches = viewModel.results.filter { $0.kind == kind }
                        if !matches.isEmpty {
                            Section(kind.title) {
                                ForEach(matches) { result in
                                    resultRow(result)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(AmbientBackground())
        .navigationTitle("Search")
        .task { await viewModel.search() }
    }

    private func resultRow(_ result: SearchViewModel.Result) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: result.kind.symbolName)
                .foregroundStyle(result.kind == .task
                    ? Color.LifePilot.signalSuccess
                    : Color.LifePilot.accentStart)
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.LifePilot.body)
                Text(result.subtitle)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }
        }
        .padding(.vertical, Spacing.xs)
        .listRowBackground(Color.LifePilot.backgroundElevated.opacity(0.82))
        .accessibilityElement(children: .combine)
    }
}

@Observable
@MainActor
public final class SearchViewModel {
    public struct Result: Identifiable, Hashable, Sendable {
        public let id: UUID
        public var title: String
        public var subtitle: String
        public var kind: SearchResultKind
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
        for task in tasks {
            let hit = task.title.lowercased().contains(needle)
                || (task.notes?.lowercased().contains(needle) ?? false)
                || task.tags.contains { $0.lowercased().contains(needle) }
            guard hit else { continue }
            matched.append(
                Result(
                    id: task.id,
                    title: task.title,
                    subtitle: task.dueDate.map {
                        "Task · \($0.formatted(date: .abbreviated, time: .shortened))"
                    } ?? "Task · Inbox",
                    kind: .task
                )
            )
        }
        for event in events {
            let hit = event.title.lowercased().contains(needle)
                || (event.location?.lowercased().contains(needle) ?? false)
                || (event.notes?.lowercased().contains(needle) ?? false)
            guard hit else { continue }
            matched.append(
                Result(
                    id: event.id,
                    title: event.title,
                    subtitle: "Event · \(event.startDate.formatted(date: .abbreviated, time: .shortened))",
                    kind: .event
                )
            )
        }
        results = matched.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}

public enum SearchResultKind: String, CaseIterable, Hashable, Sendable {
    case task
    case event

    var title: String {
        rawValue.capitalized + "s"
    }

    var symbolName: String {
        switch self {
        case .task: "checkmark.circle"
        case .event: "calendar"
        }
    }
}
