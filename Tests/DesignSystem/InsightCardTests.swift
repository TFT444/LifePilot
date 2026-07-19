import XCTest
@testable import LifePilotDesignSystem

final class InsightCardTests: XCTestCase {
    func testConstructsWithAndWithoutTrend() {
        _ = InsightCard(value: "3", label: "Late meetings this month")
        _ = InsightCard(value: "2", label: "Tight buffers this week", trend: .up)
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
