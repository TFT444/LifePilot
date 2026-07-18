import LifePilotAppShell
import SwiftUI
import WidgetKit

/// Widget Extension entry. Add this file to an Xcode Widget Extension target
/// named `LifePilotWidgets` (bundle id `com.lifepilot.app.widgets`).
@main
struct LifePilotWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayBriefingWidget()
        UpcomingAgendaWidget()
    }
}
