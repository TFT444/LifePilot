import SwiftUI
import XCTest
@testable import LifePilotDesignSystem

/// Proves every new component in this PR constructs without crashing,
/// matching the pattern established by `Tests/AppShell/LaunchSmokeTests.swift`.
/// SwiftUI view bodies aren't otherwise unit-testable without a rendering
/// harness, so this is the practical floor of coverage for pure-presentation
/// components — real visual verification happens via `DesignSystemCatalogView`'s
/// `#Preview`.
@MainActor
final class ComponentConstructionTests: XCTestCase {
    func testHeroCardConstructs() {
        _ = HeroCard { Text("Test") }
    }

    func testGhostCardConstructs() {
        _ = GhostCard(title: "Test signal")
        _ = GhostCard(title: "Test signal", subtitle: "With subtitle")
    }

    func testInsightCardConstructs() {
        _ = InsightCard(value: "1", label: "Test")
    }

    func testLoadingSkeletonConstructs() {
        _ = LoadingSkeleton()
        _ = LoadingCardSkeleton()
    }

    func testAnimatedDividerConstructs() {
        _ = AnimatedDivider()
    }

    func testSectionHeaderConstructs() {
        _ = SectionHeader(title: "Test", symbolName: "star")
    }

    func testEmptyStateViewConstructs() {
        _ = EmptyStateView(symbolName: "tray", message: "Nothing here")
    }

    func testAmbientBackgroundAndGlowCardConstruct() {
        _ = AmbientBackground()
        _ = GlowCard { Text("Glow") }
        _ = ContextTile(symbolName: "cloud", title: "22°", subtitle: "London")
        _ = StatusBanner(message: "Offline", style: .warning, actionTitle: "Retry", action: {})
    }

    func testQuickActionCardConstructs() {
        _ = QuickActionCard(symbolName: "envelope.fill", title: "Inbox")
    }

    func testDesignSystemCatalogViewConstructs() {
        _ = DesignSystemCatalogView()
    }
}
