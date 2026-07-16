import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Tasks and reminders — Inbox / Today / Upcoming / Scheduled / Completed.
public struct TasksView: View {
    @State private var viewModel: TasksViewModel

    public init(taskStore: any TaskStore) {
        _viewModel = State(initialValue: TasksViewModel(taskStore: taskStore))
    }

    public var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: Binding(
                get: { viewModel.filter },
                set: { newValue in Task { await viewModel.setFilter(newValue) } }
            )) {
                ForEach(TasksViewModel.TaskFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue.capitalized).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)

            TextField("Search", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.sm)
                .onChange(of: viewModel.searchText) { _, _ in
                    Task { await viewModel.load() }
                }

            HStack {
                TextField("Quick capture (no due date)", text: $viewModel.draftTitle)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    Task { try? await viewModel.quickCapture() }
                }
                .disabled(viewModel.draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.sm)

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
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
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
                            .swipeActions(edge: .leading) {
                                Button {
                                    Task { try? await viewModel.snooze(task, by: 3600) }
                                } label: {
                                    Label("1h", systemImage: "clock.arrow.circlepath")
                                }
                                .tint(Color.LifePilot.signalWarning)
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color.LifePilot.backgroundPrimary)
        .navigationTitle("Tasks")
        .task { await viewModel.load() }
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
                        .font(.body)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(Color.LifePilot.textPrimary)
                    if let due = task.dueDate {
                        Text(due.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(Color.LifePilot.textSecondary)
                    } else {
                        Text("Inbox · unscheduled")
                            .font(.caption)
                            .foregroundStyle(Color.LifePilot.textSecondary)
                    }
                }
                Spacer()
                Text(task.priority.rawValue)
                    .font(.caption2)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(task.title), \(task.isCompleted ? "completed" : "incomplete")")
    }
}
