# LifePilot Widgets

Widget timeline providers and SwiftUI views live in `AppShell/Widgets/TodayUpcomingWidgets.swift`.

Extension entry point: `App/LifePilotWidgets/LifePilotWidgetBundle.swift`.

## Attach in Xcode (required once)

1. File → New → Target → **Widget Extension** → product name `LifePilotWidgets`.
2. Bundle identifier: `com.lifepilot.app.widgets`.
3. Replace the generated Swift files with `App/LifePilotWidgets/LifePilotWidgetBundle.swift` (or set that file as the target’s only `@main` source).
4. Add package product dependency: **LifePilotAppShell**.
5. Embed the extension in the LifePilot app target.
6. Optional: App Group `group.com.lifepilot.app` if you later share a store with the host app.

Until the extension target is attached, widgets compile inside AppShell for CI but will not appear on the Home Screen.
