# LifePilot Widgets

Widget timeline providers and SwiftUI views live in `AppShell/Widgets/TodayUpcomingWidgets.swift` so CI can compile them with `LifePilotAppShell`.

## Shipping on device

1. In Xcode, add a **Widget Extension** target (`LifePilotWidgets`).
2. Depend on the local `LifePilotAppShell` package product.
3. Add a `@main` bundle:

```swift
import SwiftUI
import WidgetKit
import LifePilotAppShell

@main
struct LifePilotWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayBriefingWidget()
        UpcomingAgendaWidget()
    }
}
```

4. Use background task id `com.lifepilot.app.briefing.refresh` (already registered in-app) if you want refreshes after briefing updates.
