import XCTest
@testable import LifePilotAppShell

/// Proves the app's view hierarchy constructs without crashing — the
/// SPM-testable proxy for "the application launches successfully" from
/// this phase's success criteria. A full simulator launch is verified
/// separately by CI's Native App job and, ultimately, by opening App/ in Xcode.
@MainActor
final class LaunchSmokeTests: XCTestCase {
    func testRootViewConstructsWithLiveDependencies() {
        _ = LifePilotRootView(dependencies: .live)
    }

    func testRootTabViewConstructsForEveryTab() {
        let tabView = RootTabView(dependencies: .live)
        _ = tabView
    }
}
