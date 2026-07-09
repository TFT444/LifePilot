import LifePilotAppShell
import SwiftUI

/// The application entry point. Intentionally minimal — all real logic
/// (navigation, composition root, feature screens) lives in the
/// `LifePilotAppShell` SPM target, which CI builds and tests directly.
/// This file exists only to satisfy iOS's requirement for an `App`
/// conformance to launch a scene.
@main
struct LifePilotApp: App {
    var body: some Scene {
        WindowGroup {
            LifePilotRootView()
        }
    }
}
