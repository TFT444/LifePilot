import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Modal quick capture reachable from every root tab (#36).
public struct QuickCaptureView: View {
    @Binding var title: String
    let kind: AppRoute.QuickCaptureKind
    let onSubmit: () -> Void
    let onCancel: () -> Void

    public init(
        title: Binding<String>,
        kind: AppRoute.QuickCaptureKind,
        onSubmit: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        _title = title
        self.kind = kind
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(placeholder, text: $title)
                        .accessibilityLabel(placeholder)
                } footer: {
                    Text("Captured locally. External writes still require approval.")
                        .font(.LifePilot.caption)
                }
            }
            .navigationTitle(navTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: onSubmit)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
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
