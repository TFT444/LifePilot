# LifePilot Implementation Status

**Branch:** `cursor/complete-remaining-mvp-4d5a`  
**Base:** latest `origin/develop` (`bdc53d3`, includes #41 + #42)  
**Last updated:** 2026-07-17  
**Environment:** Cloud agent (Linux). `swift` / Xcode not available locally — verification via GitHub Actions (macOS).

---

## Audit summary (2026-07-17)

### What is actually implemented

| Area | Reality |
|---|---|
| SwiftUI app shell | Splash, Onboarding, Home, Timeline, Tasks, Insights, Settings; Memory via Settings/Insights |
| Design system | Real tokens + components |
| Persistence | **SwiftData** production stores; optional CloudKit when Settings toggle is on |
| Home / Briefing | Store + planning + weather/leave-by enrichment |
| Tasks | Filters, search, swipe actions, **recurrence skip / this-vs-series** |
| Timeline | Store-backed merge of events + due tasks |
| Planning | Overlap, buffers, overdue/at-risk, work hours, overload, missing break, focus window, leave-by |
| Approvals | Executor + UI; **persisted ApprovalStore only — no sample seeds** |
| Notifications | `UserNotificationsScheduler` + no-op for tests |
| EventKit | Calendar + Reminders adapters (graceful when denied) |
| Weather / MapKit | Adapters wired; leave-by uses MapKit ETA or preference buffers |
| CloudKit / BackgroundTasks | Optional sync toggle + BGAppRefresh registration |
| App Intents | Capture Inbox task + refresh briefing shortcuts |
| Widgets | Timeline providers + Today/Upcoming configs in AppShell (attach Widget Extension — see `Widgets/README.md`) |
| Icons | Raster `AppIcon-1024.png` + website favicons from `Assets/brand/logo.svg` |
| Insights / Memory | Functional local evidence UI |
| Ghost Brain | Production service stays unavailable; planning engine is source of truth |
| Scope scrub | Finance/email demo copy removed from `demo/` + `Website/public/demo.js` |

### Tooling blockers

- No local `swift` / Xcode → cannot claim simulator/UI / VoiceOver results from this environment
- Agent cannot close GitHub issues/PRs (403) — owner must close stale issues
- Widget Extension `@main` bundle still needs an Xcode target (providers ship in AppShell)

---

## Checkbox plan

### Done this cycle (`cursor/complete-remaining-mvp-4d5a`)

- [x] Approvals queue loads/persists via `ApprovalStore` (no Settings sample seeds)
- [x] Recurrence engine + Tasks skip / this-vs-series UX
- [x] Weather + MapKit leave-by briefing enrichment
- [x] Optional CloudKit preference + SwiftData CloudKit config hook
- [x] BackgroundTasks briefing refresh registration
- [x] App Intents (capture + briefing refresh)
- [x] Widget providers/views + wiring README
- [x] Demo HTML/JS finance + email scrub
- [x] #2 raster app icon + favicons (`scripts/generate-brand-icons.sh`)
- [x] Unit tests for recurrence, leave-by, Home weather path, cloud toggle

### Still open for production DoD

- [ ] Widget Extension Xcode target (`@main` WidgetBundle) — see `Widgets/README.md`
- [ ] WeatherKit live location (needs CLLocation permission UX)
- [ ] UI tests / VoiceOver device passes (needs Xcode)
- [ ] Owner: close stale GitHub issues already delivered (#3/#4/#7/#24–#38, etc.); leave #2 until icon PR merges

---

## Verification log

| When | What ran | Result |
|---|---|---|
| 2026-07-17 | Local `swift` / `xcodebuild` | **Unavailable** on agent host |
| 2026-07-17 | `cairosvg` + Pillow icon export | App icon 1024 + web favicons written |
| 2026-07-17 | GHA on PR #43 (`4fc8465`) | Build / Lint / Format / Unit Tests **green** |

---

## Dependencies / decisions locked

1. **No finance/banking/commerce** — permanent.
2. **No Apple Mail ingestion / auto-send** — permanent.
3. **No HealthKit medical MVP** — deferred.
4. Offline-first; CloudKit optional and never required.
5. Every external write: ActionProposal → Approval → Executor.
