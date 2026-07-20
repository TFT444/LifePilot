import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Tasks and reminders — Inbox / Today / Upcoming / Scheduled / Completed.
public struct TasksView: View {
    @State private var viewModel: TasksViewModel

    public init(
        taskStore: any TaskStore,
        notifications: TaskNotificationCoordinator? = nil
    ) {
        _viewModel = State(initialValue: TasksViewModel(
            taskStore: taskStore,
            notifications: notifications
        ))
    }

    public var body: some View {
        VStack(spacing: 0) {
            filterPicker
            searchField
            captureRow
            taskList
        }
        .background(AmbientBackground())
        .navigationTitle("Tasks")
        .task { await viewModel.load() }
    }

    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(TasksViewModel.TaskFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue.capitalized,
                        isSelected: viewModel.filter == filter,
                        action: { Task { await viewModel.setFilter(filter) } }
                    )
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
        .padding(.vertical, Spacing.sm)
    }

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.LifePilot.textSecondary)
            TextField("Search tasks", text: $viewModel.searchText)
                .onChange(of: viewModel.searchText) { _, _ in
                    Task { await viewModel.load() }
                }
        }
        .lifePilotField()
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
    }

    private var captureRow: some View {
        HStack(spacing: Spacing.sm) {
            TextField("Add to Inbox — no due date", text: $viewModel.draftTitle)
                .lifePilotField()
            Button {
                Task { try? await viewModel.quickCapture() }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: IconSize.sm, weight: .bold))
                    .foregroundStyle(Color.LifePilot.onAccent)
                    .frame(width: 48, height: 48)
                    .background(LinearGradient.LifePilot.accent)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Add task to Inbox")
            .disabled(viewModel.draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
    }

    @ViewBuilder
    private var taskList: some View {
        if viewModel.tasks.isEmpty, !viewModel.isLoading {
            EmptyStateView(
                symbolName: "checkmark.circle",
                message: emptyMessage
            )
            .frame(maxHeight: .infinity)
        } else {
            List {
                ForEach(viewModel.tasks) { task in
                    taskRow(task)
                        .listRowBackground(Color.LifePilot.backgroundElevated.opacity(0.82))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            trailingSwipeActions(for: task)
                        }
                        .swipeActions(edge: .leading) {
                            leadingSwipeActions(for: task)
                        }
                        .contextMenu {
                            recurrenceMenu(for: task)
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private func trailingSwipeActions(for task: TaskItem) -> some View {
        Button(role: .destructive) {
            Task { try? await viewModel.delete(task) }
        } label: {
            Label("Delete", systemImage: "trash")
        }
        Button {
            Task { try? await viewModel.duplicate(task) }
        } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
        .tint(Color.LifePilot.accentEnd)
    }

    @ViewBuilder
    private func leadingSwipeActions(for task: TaskItem) -> some View {
        Button {
            Task { try? await viewModel.snooze(task, by: 3600) }
        } label: {
            Label("1h", systemImage: "clock.arrow.circlepath")
        }
        .tint(Color.LifePilot.accentEnd)
        if task.recurrence != nil {
            Button {
                Task { try? await viewModel.skipOccurrence(task) }
            } label: {
                Label("Skip", systemImage: "forward.end")
            }
            .tint(Color.LifePilot.textSecondary)
        }
    }

    @ViewBuilder
    private func recurrenceMenu(for task: TaskItem) -> some View {
        if task.recurrence != nil {
            Button("Skip this occurrence") {
                Task { try? await viewModel.skipOccurrence(task) }
            }
            Button("Reschedule this only (+1 day)") {
                let next = (task.dueDate ?? Date()).addingTimeInterval(86_400)
                Task {
                    try? await viewModel.reschedule(task, to: next, scope: .thisOccurrenceOnly)
                }
            }
            Button("Reschedule series (+1 day)") {
                let next = (task.dueDate ?? Date()).addingTimeInterval(86_400)
                Task {
                    try? await viewModel.reschedule(task, to: next, scope: .entireSeries)
                }
            }
        }
    }

    private var emptyMessage: String {
        switch viewModel.filter {
        case .inbox: return "Inbox is empty — capture a task without a due date."
        case .today: return "Nothing due today."
        case .upcoming: return "No upcoming deadlines."
        case .scheduled: return "No scheduled tasks yet."
        case .completed: return "Completed tasks will appear here."
        }
    }

    private func taskRow(_ task: TaskItem) -> some View {
        Button {
            Task { try? await viewModel.toggleCompletion(task) }
        } label: {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(
                        task.isCompleted
                            ? Color.LifePilot.signalSuccess
                            : Color.LifePilot.textSecondary
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.LifePilot.body)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(Color.LifePilot.textPrimary)
                    dueCaption(for: task)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text(task.priority.rawValue.capitalized)
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                    if task.recurrence != nil {
                        Menu {
                            recurrenceMenu(for: task)
                        } label: {
                            Image(systemName: "repeat.circle")
                                .frame(width: 32, height: 32)
                        }
                        .accessibilityLabel("Recurrence actions for \(task.title)")
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: task))
    }

    @ViewBuilder
    private func dueCaption(for task: TaskItem) -> some View {
        if let due = task.dueDate {
            HStack(spacing: 4) {
                Text(due.formatted(date: .abbreviated, time: .shortened))
                if task.recurrence != nil {
                    Image(systemName: "repeat")
                    Text(task.recurrence?.frequency.rawValue ?? "")
                }
            }
            .font(.LifePilot.caption)
            .foregroundStyle(Color.LifePilot.textSecondary)
        } else {
            Text("Inbox · unscheduled")
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textSecondary)
        }
    }

    private func accessibilityLabel(for task: TaskItem) -> String {
        var parts = [task.title, task.isCompleted ? "completed" : "incomplete"]
        if task.recurrence != nil {
            parts.append("repeating")
        }
        return parts.joined(separator: ", ")
    }
}
