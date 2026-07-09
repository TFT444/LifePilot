import SwiftUI

/// An inline empty state for a section that currently has no content —
/// "nothing here yet, here's why." Extracted from a private type that had
/// been duplicated inside `HomeView`.
///
/// Distinct from `ComingSoonPlaceholder`: `EmptyStateView` sits inside a
/// section that otherwise has content (e.g. "no upcoming events today"
/// inside an otherwise-populated Home screen) and renders as a card.
/// `ComingSoonPlaceholder` fills an entire screen that has no
/// implementation yet (the Memory and Insights tabs). Use `EmptyStateView`
/// for "empty, for now" and `ComingSoonPlaceholder` for "not built yet."
public struct EmptyStateView: View {
    private let symbolName: String
    private let message: String

    public init(symbolName: String, message: String) {
        self.symbolName = symbolName
        self.message = message
    }

    public var body: some View {
        CardContainer {
            VStack(spacing: Spacing.sm) {
                Image(systemName: symbolName)
                    .font(.system(size: IconSize.md))
                    .foregroundStyle(Color.LifePilot.textSecondary)
                    .accessibilityHidden(true)

                Text(message)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    EmptyStateView(symbolName: "calendar", message: "Nothing else on your calendar today.")
}
