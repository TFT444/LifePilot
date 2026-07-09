import SwiftUI

/// Small indicator for risk, success, or informational signals, per
/// docs/DESIGN_SYSTEM.md's Components table. Color is never the sole
/// carrier of meaning here — every badge pairs its color with an icon and
/// text, per docs/ENGINEERING_GUIDE.md's Accessibility standard.
public struct SignalBadge: View {
    private let style: Style
    private let text: String

    public init(style: Style, text: String) {
        self.style = style
        self.text = text
    }

    public var body: some View {
        Label(text, systemImage: style.symbolName)
            .font(.LifePilot.caption)
            .foregroundStyle(style.color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(style.color.opacity(0.14))
            .clipShape(Capsule())
            .accessibilityLabel("\(style.accessibilityPrefix): \(text)")
    }

    public enum Style {
        case risk
        case success
        case info
        case priority(PriorityLevel)

        var color: Color {
            switch self {
            case .risk: Color.LifePilot.signalRisk
            case .success: Color.LifePilot.signalSuccess
            case .info: Color.LifePilot.textSecondary
            case let .priority(level): level.color
            }
        }

        var symbolName: String {
            switch self {
            case .risk: "exclamationmark.triangle.fill"
            case .success: "checkmark.circle.fill"
            case .info: "info.circle.fill"
            case let .priority(level): level.symbolName
            }
        }

        var accessibilityPrefix: String {
            switch self {
            case .risk: "Warning"
            case .success: "Success"
            case .info: "Info"
            case .priority: "Priority"
            }
        }
    }

    /// The three priority tiers a `.priority` badge can render. A
    /// `DesignSystem`-local type rather than a reuse of `TaskItem.Priority`
    /// or `RecommendationModel.Urgency` — both are domain types `Core`/
    /// `GhostBrain` own, and `DesignSystem` stays independent of either,
    /// per the plain-view-data pattern established by `BriefingCard` and
    /// `TimelineRow`. A Feature's ViewModel maps its domain-level priority
    /// to this when building a `SignalBadge`.
    public enum PriorityLevel {
        case low
        case normal
        case high

        var color: Color {
            switch self {
            case .low: Color.LifePilot.textSecondary
            case .normal: Color.LifePilot.accentEnd
            case .high: Color.LifePilot.signalRisk
            }
        }

        var symbolName: String {
            switch self {
            case .low: "arrow.down"
            case .normal: "minus"
            case .high: "arrow.up"
            }
        }
    }
}
