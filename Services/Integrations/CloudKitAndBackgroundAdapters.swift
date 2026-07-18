import Foundation
import LifePilotCore

#if canImport(BackgroundTasks)
import BackgroundTasks
#endif

/// Registers BGAppRefresh for morning briefing / leave-by recalculation.
/// No-ops outside iOS app hosts (SPM tests, macOS).
public enum BriefingBackgroundScheduler: Sendable {
    public static let refreshTaskIdentifier = "com.lifepilot.app.briefing.refresh"

    /// Call once at launch from the app entry path.
    public static func register() {
        #if os(iOS) && canImport(BackgroundTasks)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: refreshTaskIdentifier,
            using: nil
        ) { task in
            defer {
                task.setTaskCompleted(success: true)
                scheduleNext()
            }
            // Stores refresh themselves when the app becomes active;
            // background work is a wake hint only.
        }
        #endif
    }

    public static func scheduleNext(after seconds: TimeInterval = 3600) {
        #if os(iOS) && canImport(BackgroundTasks)
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: max(60, seconds))
        try? BGTaskScheduler.shared.submit(request)
        #endif
    }
}
