import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Modal quick capture reachable from every root tab (#36).
public struct QuickCaptureView: View {
    @Binding var title: String
    @Binding var kind: AppRoute.QuickCaptureKind
    let onSubmit: () -> Void
    let onCancel: () -> Void
    @FocusState private var isTitleFocused: Bool

    public init(
        title: Binding<String>,
        kind: Binding<AppRoute.QuickCaptureKind>,
        onSubmit: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        _title = title
        _kind = kind
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Capture the thought first. You can add detail later.")
                    .font(.LifePilot.body)
                    .foregroundStyle(Color.LifePilot.textSecondary)

                HStack(spacing: Spacing.sm) {
                    captureChip(.task, title: "Task", symbol: "checkmark.circle")
                    captureChip(.reminder, title: "Reminder", symbol: "bell")
                    captureChip(.event, title: "Event", symbol: "calendar")
                }

                TextField(placeholder, text: $title)
                    .lifePilotField()
                    .focused($isTitleFocused)
                    .accessibilityLabel(placeholder)

                Label(destinationCopy, systemImage: "lock.shield")
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)

                Spacer()

                Button("Save \(kind.rawValue.capitalized)", action: onSubmit)
                    .buttonStyle(.lifePilotPrimary)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(Spacing.lg)
            .background(AmbientBackground())
            .navigationTitle(navTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
            .onAppear { isTitleFocused = true }
        }
    }

    private func captureChip(
        _ value: AppRoute.QuickCaptureKind,
        title: String,
        symbol: String
    ) -> some View {
        Button {
            kind = value
        } label: {
            Label(title, systemImage: symbol)
                .font(.LifePilot.caption)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .foregroundStyle(kind == value
                    ? Color.LifePilot.onAccent
                    : Color.LifePilot.textSecondary)
                .background(kind == value
                    ? AnyShapeStyle(LinearGradient.LifePilot.accent)
                    : AnyShapeStyle(Color.LifePilot.backgroundElevated))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(kind == value ? .isSelected : [])
    }

    private var destinationCopy: String {
        switch kind {
        case .task:
            "Saves locally to your LifePilot Inbox with no invented deadline."
        case .reminder:
            "Saves a local reminder. System writes still require your approval."
        case .event:
            "Creates a local event draft. Calendar writes still require your approval."
        }
    }

    private var navTitle: String {
        switch kind {
        case .task: "New Task"
        case .reminder: "New Reminder"
        case .event: "New Event"
        }
    }

    private var placeholder: String {
        switch kind {
        case .task: "What do you need to do?"
        case .reminder: "Remind me to…"
        case .event: "Event title"
        }
    }
}
