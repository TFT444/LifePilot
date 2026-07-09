import SwiftUI

/// A single chronological entry in the Timeline, per docs/DESIGN_SYSTEM.md's
/// Components table. Takes plain view data — see `BriefingCard`'s doc
/// comment for why `DesignSystem` components avoid depending on domain
/// models directly.
public struct TimelineRow: View {
    private let content: Content

    public init(content: Content) {
        self.content = content
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .trailing, spacing: 0) {
                Text(content.time)
                    .font(.LifePilot.caption.weight(.semibold))
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }
            .frame(width: 56, alignment: .trailing)

            VStack(spacing: 0) {
                Circle()
                    .fill(content.accentColor)
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(Color.LifePilot.textSecondary.opacity(0.2))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(content.title)
                    .font(.LifePilot.body.weight(.semibold))
                    .foregroundStyle(Color.LifePilot.textPrimary)

                if let subtitle = content.subtitle {
                    Text(subtitle)
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
            }
            .padding(.bottom, Spacing.md)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    /// Plain view data for `TimelineRow`.
    public struct Content {
        public let time: String
        public let title: String
        public let subtitle: String?
        public let accentColor: Color

        public init(time: String, title: String, subtitle: String? = nil, accentColor: Color = Color.LifePilot.accentStart) {
            self.time = time
            self.title = title
            self.subtitle = subtitle
            self.accentColor = accentColor
        }
    }
}
