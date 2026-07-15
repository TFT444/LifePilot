import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Tasks and reminders — Inbox / Today / Upcoming / Completed with quick capture.
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

            HStack {
                TextField("Quick capture", text: $viewModel.draftTitle)
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
                    message: "No tasks here — capture something you need to do today."
                )
                .frame(maxHeight: .infinity)
            } else {
                List(viewModel.tasks) { task in
                    Button {
                        Task { try? await viewModel.toggleCompletion(task) }
                    } label: {
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.isCompleted ? Color.LifePilot.signalSuccess : Color.LifePilot
                                    .textSecondary
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
                .listStyle(.plain)
            }
        }
        .background(Color.LifePilot.backgroundPrimary)
        .navigationTitle("Tasks")
        .task { await viewModel.load() }
    }
}
