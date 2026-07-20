import LifePilotCore
import SwiftUI

/// The product mark rendered without relying on an app-bundle asset.
public struct BrandMark: View {
    private let size: CGFloat

    public init(size: CGFloat = 52) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .fill(Color.LifePilot.backgroundElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                        .stroke(LinearGradient.LifePilot.hero.opacity(0.55), lineWidth: 1)
                )
            Text("L")
                .font(.system(size: size * 0.58, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient.LifePilot.hero)
                .shadow(color: Color.LifePilot.accentStart.opacity(0.55), radius: size * 0.12)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Shared capsule selector for Timeline, Tasks, Memory, and Insights.
public struct FilterChip: View {
    private let title: String
    private let isSelected: Bool
    private let action: () -> Void

    public init(title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.LifePilot.caption)
                .foregroundStyle(isSelected ? Color.LifePilot.onAccent : Color.LifePilot.textSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    isSelected
                        ? AnyShapeStyle(LinearGradient.LifePilot.accent)
                        : AnyShapeStyle(Color.LifePilot.backgroundElevated)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? Color.clear : Color.LifePilot.borderSubtle,
                            lineWidth: 1
                        )
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Tokenised input treatment that remains opaque under Reduce Transparency.
public struct StyledFieldModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init() {}

    public func body(content: Content) -> some View {
        content
            .font(.LifePilot.body)
            .padding(.horizontal, Spacing.md)
            .frame(minHeight: 48)
            .background(
                reduceTransparency
                    ? AnyShapeStyle(Color.LifePilot.backgroundElevated)
                    : AnyShapeStyle(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .stroke(Color.LifePilot.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
    }
}

extension View {
    public func lifePilotField() -> some View {
        modifier(StyledFieldModifier())
    }

    /// One-time depth settle for primary surfaces. Never loops and respects Reduce Motion.
    public func lifePilotDepthEntrance(delay: Double = 0) -> some View {
        modifier(DepthEntranceModifier(delay: delay))
    }
}

public struct DepthEntranceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var emerged = false
    private let delay: Double

    public init(delay: Double = 0) {
        self.delay = delay
    }

    public func body(content: Content) -> some View {
        content
            .opacity(emerged || reduceMotion ? 1 : 0.72)
            .offset(y: emerged || reduceMotion ? 0 : 10)
            .rotation3DEffect(
                .degrees(emerged || reduceMotion ? 0 : 3),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.55
            )
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(Motion.spring.delay(delay)) {
                    emerged = true
                }
            }
    }
}

/// Compact live context. It replaces dashboard-style stat tiles.
public struct ContextRibbon: View {
    private let weather: String?
    private let leaveBy: String?
    private let freshness: String

    public init(weather: String?, leaveBy: String?, freshness: String) {
        self.weather = weather
        self.leaveBy = leaveBy
        self.freshness = freshness
    }

    public var body: some View {
        GlassSurface(cornerRadius: CornerRadius.full) {
            HStack(spacing: Spacing.sm) {
                if let weather {
                    ribbonItem(symbol: "cloud.sun.fill", text: weather)
                    divider
                }
                if let leaveBy {
                    ribbonItem(symbol: "location.fill", text: leaveBy)
                    divider
                }
                ribbonItem(symbol: "checkmark.icloud.fill", text: freshness)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .accessibilityElement(children: .combine)
    }

    private func ribbonItem(symbol: String, text: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.LifePilot.caption)
            .foregroundStyle(Color.LifePilot.textSecondary)
            .lineLimit(1)
    }

    private var divider: some View {
        Circle()
            .fill(Color.LifePilot.borderSubtle)
            .frame(width: 3, height: 3)
    }
}

/// Highest-value preparation, visually elevated above ordinary cards.
public struct PreparationCard: View {
    private let eyebrow: String
    private let title: String
    private let detail: String
    private let symbolName: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(
        eyebrow: String,
        title: String,
        detail: String,
        symbolName: String = "sparkles",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.detail = detail
        self.symbolName = symbolName
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label(eyebrow.uppercased(), systemImage: symbolName)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.accentTeal)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(Color.LifePilot.textSecondary)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(.LifePilot.titleMedium)
                .foregroundStyle(Color.LifePilot.textPrimary)
            Text(detail)
                .font(.LifePilot.body)
                .foregroundStyle(Color.LifePilot.textSecondary)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.lifePilotPrimary)
            }
        }
        .padding(Spacing.lg)
        .background(Color.LifePilot.backgroundElevated)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .stroke(LinearGradient.LifePilot.hero.opacity(0.7), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
        .lifePilotShadow(ShadowStyle.LifePilot.elevated)
        .accessibilityElement(children: .contain)
    }
}

/// Calm "brain" moment for evidence-led Insights, not a literal 3D brain.
public struct InsightHero: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var illuminated = false

    private let title: String
    private let detail: String

    public init(title: String, detail: String) {
        self.title = title
        self.detail = detail
    }

    public var body: some View {
        HeroCard {
            HStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.LifePilot.hero.opacity(0.28))
                        .frame(width: 72, height: 72)
                        .blur(radius: illuminated ? 3 : 8)
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(LinearGradient.LifePilot.hero)
                }
                .scaleEffect(illuminated ? 1.03 : 0.97)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.LifePilot.titleMedium)
                        .foregroundStyle(Color.LifePilot.textPrimary)
                    Text(detail)
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatCount(2, autoreverses: true)) {
                illuminated = true
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Connection state row with icon + text, so status never relies on colour.
public struct ConnectionStatusRow: View {
    private let title: String
    private let state: PermissionState
    private let detail: String?

    public init(title: String, state: PermissionState, detail: String? = nil) {
        self.title = title
        self.state = state
        self.detail = detail
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: symbolName)
                .foregroundStyle(tint)
                .frame(width: IconSize.md)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.LifePilot.body)
                    .foregroundStyle(Color.LifePilot.textPrimary)
                if let detail {
                    Text(detail)
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
            }
            Spacer()
            Text(stateLabel)
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var symbolName: String {
        switch state {
        case .authorized: "checkmark.circle.fill"
        case .limited: "circle.lefthalf.filled"
        case .denied: "xmark.circle.fill"
        case .restricted: "lock.circle.fill"
        case .unavailable: "minus.circle.fill"
        case .notRequested: "circle.dotted"
        }
    }

    private var tint: Color {
        switch state {
        case .authorized: Color.LifePilot.signalSuccess
        case .denied, .restricted: Color.LifePilot.signalRisk
        case .limited: Color.LifePilot.accentStart
        case .unavailable, .notRequested: Color.LifePilot.textSecondary
        }
    }

    private var stateLabel: String {
        switch state {
        case .notRequested: "Not connected"
        case .authorized: "Connected"
        case .denied: "Denied"
        case .restricted: "Restricted"
        case .limited: "Limited"
        case .unavailable: "Unavailable"
        }
    }
}
