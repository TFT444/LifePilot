import XCTest
@testable import LifePilotCore

final class GhostBrainTests: XCTestCase {
    func testInitializesWithAVersion() {
        let ghostBrain = GhostBrain()
        XCTAssertFalse(ghostBrain.version.isEmpty)
    }
}
