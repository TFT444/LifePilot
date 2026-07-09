import XCTest
@testable import LifePilotDesignSystem

final class SignalBadgeTests: XCTestCase {
    func testConstructsWithEveryStyle() {
        _ = SignalBadge(style: .risk, text: "High Risk")
        _ = SignalBadge(style: .success, text: "Approved")
        _ = SignalBadge(style: .info, text: "Info")
        _ = SignalBadge(style: .priority(.low), text: "Low")
        _ = SignalBadge(style: .priority(.normal), text: "Normal")
        _ = SignalBadge(style: .priority(.high), text: "High")
    }

    func testPriorityLevelsHaveDistinctSymbols() {
        let symbols = Set([
            SignalBadge.PriorityLevel.low,
            .normal,
            .high,
        ].map(\.symbolName))

        XCTAssertEqual(symbols.count, 3, "Each priority level should have a visually distinct symbol")
    }

    func testPriorityLevelsHaveDistinctColors() {
        // Compared by description since Color doesn't conform to Equatable
        // in a way that reliably distinguishes dynamic (light/dark) colors.
        let descriptions = Set([
            SignalBadge.PriorityLevel.low,
            .normal,
            .high,
        ].map { "\($0.color)" })

        XCTAssertEqual(descriptions.count, 3, "Each priority level should have a visually distinct color")
    }
}
