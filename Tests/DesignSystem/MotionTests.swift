import XCTest
@testable import LifePilotDesignSystem

final class MotionTests: XCTestCase {
    func testAllMotionTokensAreConstructible() {
        // Animation doesn't expose its internal parameters for inspection,
        // so this asserts the tokens exist and compile with the expected
        // type — the meaningful verification (that Reduce Motion actually
        // disables animation) lives in the View.lifePilotAnimation
        // modifier itself, exercised indirectly via any view that adopts
        // it (GhostCard, LoadingSkeleton, AnimatedDivider, CardElevationModifier).
        _ = Motion.standard
        _ = Motion.quick
        _ = Motion.deliberate
        _ = Motion.spring
        _ = Motion.press
        _ = Motion.loading
    }
}
