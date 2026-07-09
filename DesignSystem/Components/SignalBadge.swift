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

        var color: Color {
            switch self {
            case .risk: return Color.LifePilot.signalRisk
            case .success: return Color.LifePilot.signalSuccess
            case .info: return Color.LifePilot.textSecondary
            }
        }

        var symbolName: String {
            switch self {
            case .risk: return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var accessibilityPrefix: String {
            switch self {
            case .risk: return "Warning"
            case .success: return "Success"
            case .info: return "Info"
            }
        }
    }
}
