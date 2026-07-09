import SwiftUI

/// Presents a recommended action with reasoning and approve/dismiss
/// controls, per docs/DESIGN_SYSTEM.md's Components table. This is the UI
/// expression of the Approve stage in README.md's Core Philosophy — nothing
/// reaches Execution without passing through a screen shaped like this one.
public struct ApprovalSheet: View {
    private let content: Content
    private let onApprove: () -> Void
    private let onDismiss: () -> Void

    public init(content: Content, onApprove: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.content = content
        self.onApprove = onApprove
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(content.title)
                    .font(.LifePilot.titleMedium)
                    .foregroundStyle(Color.LifePilot.textPrimary)

                Text(content.reasoning)
                    .font(.LifePilot.body)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }

            VStack(spacing: Spacing.sm) {
                Button("Approve", action: onApprove)
                    .buttonStyle(.lifePilotPrimary)

                Button("Dismiss", action: onDismiss)
                    .buttonStyle(.lifePilotSecondary)
            }
        }
        .padding(Spacing.lg)
    }

    /// Plain view data for `ApprovalSheet`.
    public struct Content {
        public let title: String
        public let reasoning: String

        public init(title: String, reasoning: String) {
            self.title = title
            self.reasoning = reasoning
        }
    }
}
