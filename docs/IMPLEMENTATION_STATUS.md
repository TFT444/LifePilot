# LifePilot Implementation Status

**Branch:** `cursor/issues-today-4d5a` (PR #41)  
**Base:** latest `origin/develop` (includes #42 solo-admin merge tooling)  
**Last updated:** 2026-07-16  
**Environment:** Cloud agent (Linux). `swift` / Xcode not available locally — verification via GitHub Actions (macOS).

---

## Audit summary (2026-07-16)

### What is actually implemented

| Area | Reality |
|---|---|
| SwiftUI app shell | Splash, Onboarding, Home, Timeline, Tasks, Insights, Settings; Memory via Settings/Insights |
| Design system | Real tokens + components |
| Persistence | **SwiftData** production stores (`PersistenceController` + `SwiftData*Store`); in-memory for tests/previews |
| Home / Briefing | Store + `DeterministicPlanningEngine` backed (not mock GhostBrain) |
| Tasks | Inbox / Today / Upcoming / Scheduled / Completed; search; swipe delete/duplicate/snooze; capture **without** arbitrary deadline |
| Timeline | Store-backed merge of events + due tasks |
| Planning | Overlap, buffers, overdue/at-risk, work hours, overload, missing break, focus window |
| Approvals | Executor + UI; SwiftData approval/audit store wired in composition |
| Notifications | `UserNotificationsScheduler` (real adapter) + no-op for tests |
| EventKit | `EventKitCalendarIntegration` + `EventKitRemindersIntegration` (graceful when denied) |
| Weather / MapKit / CloudKit | Protocols + unavailable doubles (real adapters still pending) |
| Insights / Memory | Functional local evidence UI (not ComingSoon placeholders) |
| Ghost Brain | Production service stays unavailable; planning engine is the source of truth |
| Scope scrub | Finance/shopping/HealthKit diagram labels removed; EmailMessage/MockEmail deleted |

### Tooling blockers

- No local `swift` / Xcode → cannot claim simulator/UI results from this environment
- Agent cannot close/merge PRs or change branch protection (use `scripts/enable-solo-admin-merge.sh` as admin)
- PR #39 is fully contained in #41 (agent cannot close #39 — owner should)

---

## Checkbox plan

### Done this cycle

- [x] Sync PR #41 with latest `develop`
- [x] Confirm #39 is ancestor of #41
- [x] Repository audit + this status file
- [x] SwiftData repositories for tasks/events/preferences/memory/approvals/audit
- [x] Wire `AppDependencies.live` to SwiftData + EventKit + UserNotifications
- [x] Store-backed Home briefing + freshness/refresh
- [x] Tasks capture without +1h deadline; scheduled filter; search; swipe actions
- [x] Memory + Insights screens (evidence-based, no finance/medical)
- [x] Planning: missing break + focus window rules
- [x] Remove EmailMessage / MockEmail; scrub architecture.svg + roadmap agent roster
- [x] SwiftData + Home ViewModel tests

### Still open for production DoD

- [ ] Full recurrence edit/skip/series UX
- [ ] WeatherKit + MapKit real adapters + travel leave-by
- [ ] CloudKit optional sync + BackgroundTasks
- [ ] App Intents + widgets
- [ ] UI tests / VoiceOver device passes (needs Xcode)
- [ ] Approval queue without sample seeds in production Settings
- [ ] Close stale GitHub issues/PRs (#3/#4/#7/#16/#20/#22/#23/#39) as owner
- [ ] Demo web HTML finance/email copy cleanup

---

## Verification log

| When | What ran | Result |
|---|---|---|
| 2026-07-16 | Local `swift` / `xcodebuild` | **Unavailable** on agent host |
| 2026-07-16 | Sync merge `develop` → `cursor/issues-today-4d5a` | Clean merge (`#42` included) |
| Pending | GHA on latest push | Source of truth after push |

---

## Dependencies / decisions locked

1. **No finance/banking/commerce** — permanent.
2. **No HealthKit / medical MVP** — deferred only.
3. **No Apple Mail ingestion / automatic sending** — removed models/mocks.
4. **Offline-first** without account; AI optional and never holds execution credentials.
5. **Composition:** `App → AppShell → Features → Core protocols` ← `Services` / adapters.
6. **In-memory stores** remain for tests/previews only; production uses SwiftData.
