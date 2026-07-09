import XCTest
@testable import LifePilotDesignSystem

final class InsightCardTests: XCTestCase {
    func testConstructsWithAndWithoutTrend() {
        _ = InsightCard(value: "4.5 hrs", label: "Time saved this week")
        _ = InsightCard(value: "94%", label: "Productivity score", trend: .up)
        _ = InsightCard(value: "2", label: "Conflicts resolved", trend: .down)
        _ = InsightCard(value: "0", label: "No change", trend: .flat)
    }

    func testEveryTrendHasADistinctAccessibilityDescription() {
        let descriptions = Set([
            InsightCard.Trend.up,
            .down,
            .flat,
        ].map(\.accessibilityDescription))

        XCTAssertEqual(descriptions.count, 3)
    }
}
