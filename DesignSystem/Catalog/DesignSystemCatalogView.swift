import SwiftUI
import LifePilotCore

/// The internal design-system showcase — every reusable component in
/// `DesignSystem/Components/`, rendered together for visual review. Not
/// part of the shipping app's navigation (per this PR's mandate not to
/// touch `AppShell`/`RootTabView`); reach it via its `#Preview` in Xcode,
/// or embed it temporarily in `RootTabView` during local development.
///
/// This view exists to make the design system reviewable as a whole,
/// per docs/DESIGN_SYSTEM.md's note that components should have "a
/// corresponding entry" for preview alongside their implementation.
public struct DesignSystemCatalogView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                catalogHeader
                colorSection
                typographySection
                buttonSection
                badgeSection
                cardSection
                heroSection
                timelineSection
                loadingSection
                dividerSection
                glassSection
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xl)
        }
        .background(Color.LifePilot.backgroundPrimary)
    }

    private var catalogHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Design System")
                .font(.LifePilot.titleLarge)
                .foregroundStyle(Color.LifePilot.textPrimary)
            Text("Every reusable component, in one place.")
                .font(.LifePilot.body)
                .foregroundStyle(Color.LifePilot.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Color

    private var colorSection: some View {
        catalogSection(title: "Color", symbolName: "paintpalette.fill") {
            HStack(spacing: Spacing.sm) {
                colorSwatch("Accent Start", Color.LifePilot.accentStart)
                colorSwatch("Accent End", Color.LifePilot.accentEnd)
                colorSwatch("Risk", Color.LifePilot.signalRisk)
                colorSwatch("Success", Color.LifePilot.signalSuccess)
            }
        }
    }

    private func colorSwatch(_ name: String, _ color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                .fill(color)
                .frame(height: 44)
            Text(name)
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name) color swatch")
    }

    // MARK: - Typography

    private var typographySection: some View {
        catalogSection(title: "Typography", symbolName: "textformat") {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Title Large").font(.LifePilot.titleLarge)
                Text("Title Medium").font(.LifePilot.titleMedium)
                Text("Body").font(.LifePilot.body)
                Text("Caption").font(.LifePilot.caption)
            }
            .foregroundStyle(Color.LifePilot.textPrimary)
        }
    }

    // MARK: - Buttons

    private var buttonSection: some View {
        catalogSection(title: "Buttons", symbolName: "rectangle.and.hand.point.up.left.fill") {
            VStack(spacing: Spacing.sm) {
                Button("Primary Action") {}
                    .buttonStyle(.lifePilotPrimary)
                Button("Secondary Action") {}
                    .buttonStyle(.lifePilotSecondary)
            }
        }
    }

    // MARK: - Badges

    private var badgeSection: some View {
        catalogSection(title: "Badges", symbolName: "tag.fill") {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    SignalBadge(style: .risk, text: "High Risk")
                    SignalBadge(style: .success, text: "Approved")
                    SignalBadge(style: .info, text: "Info")
                }
                HStack(spacing: Spacing.sm) {
                    SignalBadge(style: .priority(.low), text: "Low")
                    SignalBadge(style: .priority(.normal), text: "Normal")
                    SignalBadge(style: .priority(.high), text: "High")
                }
            }
        }
    }

    // MARK: - Cards

    private var cardSection: some View {
        catalogSection(title: "Cards", symbolName: "rectangle.stack.fill") {
            VStack(spacing: Spacing.sm) {
                BriefingCard(content: .init(
                    title: "Leave 15 minutes early for your 10:00 AM",
                    reasoning: "Traffic is heavier than normal on your usual route.",
                    sourceAgent: .travel,
                    riskBadgeText: "Medium"
                ))
                GhostCard(title: "Rain expected this afternoon", subtitle: "60% chance starting around 3:00 PM")
                InsightCard(value: "4.5 hrs", label: "Time saved this week", trend: .up)
                QuickActionCard(symbolName: "envelope.fill", title: "Inbox")
                EmptyStateView(symbolName: "tray", message: "Nothing here yet.")
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        catalogSection(title: "Hero Card", symbolName: "sparkles") {
            HeroCard {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Wednesday, July 9")
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                    Text("Good morning, Alex")
                        .font(.LifePilot.titleLarge)
                        .foregroundStyle(Color.LifePilot.textPrimary)
                }
            }
        }
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        catalogSection(title: "Timeline Row", symbolName: "list.bullet") {
            CardContainer {
                VStack(spacing: 0) {
                    TimelineRow(content: .init(time: "9:00 AM", title: "Morning Standup", subtitle: "Zoom"))
                    TimelineRow(content: .init(time: "12:30 PM", title: "Lunch with Sam", subtitle: "Tatte Bakery"))
                }
            }
        }
    }

    // MARK: - Loading

    private var loadingSection: some View {
        catalogSection(title: "Loading Skeleton", symbolName: "hourglass") {
            LoadingCardSkeleton()
        }
    }

    // MARK: - Divider

    private var dividerSection: some View {
        catalogSection(title: "Animated Divider", symbolName: "minus") {
            AnimatedDivider()
        }
    }

    // MARK: - Glass

    private var glassSection: some View {
        catalogSection(title: "Glass Surface", symbolName: "square.stack.3d.up.fill") {
            GlassSurface(cornerRadius: CornerRadius.md) {
                Text("Floating chrome")
                    .font(.LifePilot.body)
                    .foregroundStyle(Color.LifePilot.textPrimary)
                    .padding(Spacing.md)
            }
            .background(LinearGradient.LifePilot.accent)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        }
    }

    // MARK: - Shared Section Layout

    @ViewBuilder
    private func catalogSection<Content: View>(
        title: String,
        symbolName: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: title, symbolName: symbolName)
            content()
        }
    }
}

#Preview("Light") {
    DesignSystemCatalogView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    DesignSystemCatalogView()
        .preferredColorScheme(.dark)
}
