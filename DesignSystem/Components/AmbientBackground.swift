import SwiftUI

/// Soft radial washes behind briefing / timeline screens (Phase 2 dark glass look).
public struct AmbientBackground: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color.LifePilot.backgroundPrimary
            RadialGradient(
                colors: [
                    Color.LifePilot.accentStart.opacity(0.28),
                    Color.clear,
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 320
            )
            RadialGradient(
                colors: [
                    Color.LifePilot.accentEnd.opacity(0.18),
                    Color.clear,
                ],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 280
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Elevated card with a subtle accent border for Phase 2 glass-adjacent surfaces.
public struct GlowCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.LifePilot.backgroundElevated.opacity(0.92))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .stroke(
                        LinearGradient.LifePilot.accent.opacity(0.35),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
            .lifePilotShadow(ShadowStyle.LifePilot.card)
    }
}

/// Compact context tile used on Home (weather, meetings, leave-by).
public struct ContextTile: View {
    private let symbolName: String
    private let title: String
    private let subtitle: String
    private let accent: Color

    public init(
        symbolName: String,
        title: String,
        subtitle: String,
        accent: Color = Color.LifePilot.accentEnd
    ) {
        self.symbolName = symbolName
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: symbolName)
                .font(.system(size: IconSize.sm, weight: .semibold))
                .foregroundStyle(accent)
            Text(title)
                .font(.LifePilot.titleMedium)
                .foregroundStyle(Color.LifePilot.textPrimary)
                .lineLimit(2)
            Text(subtitle)
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textSecondary)
                .lineLimit(2)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
        .background(Color.LifePilot.backgroundElevated)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .stroke(accent.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Banner for offline / denied / stale states — never silent failure.
public struct StatusBanner: View {
    public enum Style: String, Sendable, Equatable {
        case info
        case warning
        case risk
    }

    private let message: String
    private let style: Style
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(
        message: String,
        style: Style = .info,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.message = message
        self.style = style
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            Image(systemName: symbolName)
                .foregroundStyle(tint)
            Text(message)
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.accentEnd)
            }
        }
        .padding(Spacing.md)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var symbolName: String {
        switch style {
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .risk: "xmark.octagon.fill"
        }
    }

    private var tint: Color {
        switch style {
        case .info: Color.LifePilot.accentEnd
        case .warning: Color.LifePilot.accentStart
        case .risk: Color.LifePilot.signalRisk
        }
    }
}
