import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Parse, review, correct, and commit one natural-language capture.
public struct QuickCaptureView: View {
    @State private var viewModel: QuickCaptureViewModel
    @FocusState private var isInputFocused: Bool
    private let onSaved: (String) -> Void
    private let onCancel: () -> Void

    public init(
        dependencies: QuickCaptureDependencies,
        initialDestination: AppRoute.QuickCaptureKind = .task,
        onSaved: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _viewModel = State(
            initialValue: QuickCaptureViewModel(
                dependencies: dependencies,
                initialDestination: initialDestination
            )
        )
        self.onSaved = onSaved
        self.onCancel = onCancel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if viewModel.isReviewing {
                        reviewForm
                    } else {
                        captureForm
                    }
                }
                .padding(Spacing.lg)
            }
            .scrollContentBackground(.hidden)
            .background(AmbientBackground())
            .navigationTitle(viewModel.isReviewing ? "Review Capture" : "Quick Capture")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
            .onAppear { isInputFocused = true }
        }
    }

    private var captureForm: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Describe the task, reminder, or event naturally. "
                + "LifePilot will show what it understood before saving.")
                .font(.LifePilot.body)
                .foregroundStyle(Color.LifePilot.textSecondary)

            destinationPicker

            TextField("What should LifePilot capture?", text: binding(\.inputText), axis: .vertical)
                .lineLimit(3 ... 6)
                .lifePilotField()
                .focused($isInputFocused)
                .accessibilityLabel("Natural language capture")

            Label("Nothing is saved until you review the structured details.", systemImage: "lock.shield")
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textSecondary)

            Button("Review Details") {
                viewModel.prepareReview()
            }
            .buttonStyle(.lifePilotPrimary)
            .disabled(!viewModel.canReview)
        }
    }

    private var reviewForm: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            destinationPicker

            TextField("Title", text: binding(\.title))
                .lifePilotField()
                .accessibilityLabel("Captured title")

            scheduleFields

            TextField("Location (optional)", text: binding(\.location))
                .lifePilotField()
                .accessibilityLabel("Captured location")

            TextField("Notes (optional)", text: binding(\.notes), axis: .vertical)
                .lineLimit(2 ... 5)
                .lifePilotField()
                .accessibilityLabel("Captured notes")

            Picker("Repeat", selection: binding(\.recurrence)) {
                ForEach(CaptureRecurrenceChoice.allCases, id: \.self) { choice in
                    Text(choice.displayName).tag(choice)
                }
            }
            .accessibilityLabel("Recurrence")
            if viewModel.recurrence != .none {
                Stepper(
                    "Repeat interval: \(viewModel.recurrenceInterval)",
                    value: binding(\.recurrenceInterval),
                    in: 1 ... 30
                )
                .accessibilityLabel("Recurrence interval")
            }

            ambiguityReview

            if let errorMessage = viewModel.errorMessage {
                StatusBanner(message: errorMessage, style: .warning)
            }

            Button(viewModel.isSaving ? "Saving..." : saveButtonTitle) {
                Task {
                    if let message = await viewModel.save() {
                        onSaved(message)
                    }
                }
            }
            .buttonStyle(.lifePilotPrimary)
            .disabled(!viewModel.canSave)

            Button("Edit Original Text") {
                viewModel.editOriginalText()
                isInputFocused = true
            }
            .buttonStyle(.lifePilotSecondary)
        }
    }

    @ViewBuilder
    private var scheduleFields: some View {
        Toggle(scheduleToggleTitle, isOn: binding(\.hasSchedule))
        if viewModel.hasSchedule {
            DatePicker(
                viewModel.destination == .event ? "Starts" : "When",
                selection: binding(\.scheduledAt),
                displayedComponents: [.date, .hourAndMinute]
            )
        }
    }

    @ViewBuilder
    private var ambiguityReview: some View {
        if !viewModel.ambiguities.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(viewModel.ambiguities, id: \.self) { ambiguity in
                    StatusBanner(message: ambiguity.message, style: .warning)
                }
                Toggle("I confirmed the corrected date and time", isOn: binding(\.ambiguityConfirmed))
                    .font(.LifePilot.caption)
                    .accessibilityLabel("Confirm ambiguous capture details")
            }
        }
    }

    private var destinationPicker: some View {
        Picker("Destination", selection: binding(\.destination)) {
            Text("LifePilot Task").tag(AppRoute.QuickCaptureKind.task)
            Text("Apple Reminder").tag(AppRoute.QuickCaptureKind.reminder)
            Text("Local Event").tag(AppRoute.QuickCaptureKind.event)
        }
        .pickerStyle(.menu)
        .accessibilityLabel("Capture destination")
    }

    private var saveButtonTitle: String {
        switch viewModel.destination {
        case .task: "Save LifePilot Task"
        case .reminder: "Send to Approvals"
        case .event: "Save Local Event"
        }
    }

    private var scheduleToggleTitle: String {
        viewModel.destination == .event ? "Set event date and time" : "Add date and time"
    }

    private func binding<Value>(_ keyPath: ReferenceWritableKeyPath<QuickCaptureViewModel, Value>) -> Binding<Value> {
        Binding(
            get: { viewModel[keyPath: keyPath] },
            set: { viewModel[keyPath: keyPath] = $0 }
        )
    }
}
