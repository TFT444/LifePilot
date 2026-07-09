import XCTest
@testable import LifePilotDesignSystem

final class ColorTokenTests: XCTestCase {
    func testSpacingTokensFollowEightPointGrid() {
        XCTAssertEqual(Spacing.xs, 4)
        XCTAssertEqual(Spacing.sm, 8)
        XCTAssertEqual(Spacing.md, 16)
        XCTAssertEqual(Spacing.lg, 24)
        XCTAssertEqual(Spacing.xl, 32)
    }

    func testCornerRadiusTokensAreOrderedAscending() {
        XCTAssertLessThan(CornerRadius.sm, CornerRadius.md)
        XCTAssertLessThan(CornerRadius.md, CornerRadius.lg)
        XCTAssertLessThan(CornerRadius.lg, CornerRadius.full)
    }

    func testIconSizeTokensAreOrderedAscending() {
        XCTAssertLessThan(IconSize.sm, IconSize.md)
        XCTAssertLessThan(IconSize.md, IconSize.lg)
        XCTAssertLessThan(IconSize.lg, IconSize.xl)
    }
}
