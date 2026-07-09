import XCTest
@testable import LifePilotCore

final class RiskLevelTests: XCTestCase {
    func testOrdering() {
        XCTAssertLessThan(RiskLevel.low, RiskLevel.medium)
        XCTAssertLessThan(RiskLevel.medium, RiskLevel.high)
    }
}
