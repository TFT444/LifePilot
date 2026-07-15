# LifePilot Personas

**Issue:** [#25](https://github.com/TFT444/lifepilot/issues/25)  
**Status:** Complete for daily-life MVP research  
**Last updated:** 2026-07-15  
**Scope baseline:** [`docs/IMPLEMENTATION_STATUS.md`](../IMPLEMENTATION_STATUS.md), [`.cursor/rules/lifepilot-mvp.mdc`](../../.cursor/rules/lifepilot-mvp.mdc)

Five named primary personas ground the daily-life MVP. Scenarios cover reminders, personal events, work schedules, conflicts, travel, and **approval-gated** actions. Communication to others is manual (share / copy); there is no Apple Mail ingestion or automatic sending.

---

## Permission legend

| Level | Meaning |
|---|---|
| **Necessary** | Core value for this persona fails without it |
| **Optional** | Improves prep quality; app must degrade gracefully if denied |
| **Declined by design** | Persona prefers never to grant; product must still work |

MVP never requires HealthKit, Mail, banking, or shopping permissions.

---

## 1. Avery Chen — Busy professional

**Archetype:** Busy professional balancing meetings and personal obligations  
**Age / context:** 34, product manager, hybrid office 3 days/week, partnered, no kids yet  
**Devices:** iPhone primary; MacBook for long planning; Apple Watch notifications

### Goals

- See one coherent “what today requires” before standup
- Protect focus blocks without missing hard meetings
- Keep personal dentist / travel prep from colliding with work

### Failure modes

- Opens calendar + reminders + notes separately and still misses a buffer
- Approves nothing because proposals lack evidence → distrust
- Over-notified; disables notifications entirely

### Accessibility needs

- Dynamic Type up to XXXL on Briefing and Approvals
- VoiceOver order: conflict summary before action buttons
- Reduce Motion: static conflict cards (no pulsing urgency)

### Trust concerns

- Work calendar titles may be confidential — needs **Private** / redacted lock-screen previews
- Will not grant location “always”; may allow once/while using for commute prep
- Rejects any auto-send of messages to coworkers

### Day in the life

06:45 Briefing: two morning meetings, one personal pharmacy pickup, rain note if weather optional data present.  
08:10 Conflict: dental exam overlaps standup buffer — proposal to shift personal event (Approval required before Calendar write).  
12:00 Reminder: “Prep QBR slides” from Tasks, not from email scrape.  
17:30 Travel: optional MapKit ETA if Location allowed; otherwise time-only buffer warning.  
21:00 Memory: after rejecting “move 1:1” twice, preference “don’t move 1:1s without asking” confirmed.

### Scenario coverage

| Scenario | How LifePilot helps |
|---|---|
| Reminders | Local + Reminders sync (if connected) for pickup and prep |
| Personal events | Pharmacy / dentist on Timeline with Personal context |
| Work schedules | Meetings + focus blocks; work-hours overload Insight |
| Conflicts | Overlap/buffer detection → Approval proposal |
| Travel | Optional weather/ETA on Home briefing section |
| Approvals | Calendar move / reminder create never silent |

### Permissions

| Permission | Level | Notes |
|---|---|---|
| Calendar | **Necessary** | Dense schedule is core |
| Reminders | **Necessary** | Prep tasks often live here |
| Notifications | **Necessary** | Briefing + approval prompts |
| Location | Optional | Commute/ETA only |
| Contacts | Declined by design | Not needed for MVP |
| Mail / Health | Declined by design | Out of scope |

---

## 2. Jordan Okonkwo — Shift worker

**Archetype:** Shift or flexible worker with changing schedules  
**Age / context:** 29, hospital tech, rotating days/nights, shares apartment  
**Devices:** iPhone only; uses Mac rarely at library

### Goals

- Trust that “today” means *this shift*, not a 9–5 assumption
- Sleep protection: quiet hours aligned to off-shift
- Catch handoff / overtime schedule changes without reconstructing the week manually

### Failure modes

- App assumes Monday–Friday and mislabels night shift as “tomorrow morning”
- Notifications during sleep → uninstall
- Double-books personal gym against a late call-in shift

### Accessibility needs

- High-contrast conflict and overdue states (color not sole cue)
- Large tap targets on Approvals when exhausted post-shift
- Plain language; avoid corporate jargon (“QBR”, “stand-up”)

### Trust concerns

- Coworker names on shared ward calendar may be sensitive — Shared context redaction in notifications
- Suspicious of cloud sync; prefers local-only default
- Will revoke Calendar if writes happen without Approval

### Day in the life

14:00 Wakes; Briefing for night shift starting 19:00: prep checklist, commute weather if optional Location on.  
16:30 Reminder: “Pack scrubs + badge.”  
18:10 Conflict: friend birthday dinner overlaps shift start — shows conflict, proposes decline/move of personal event (user Approves).  
07:00 End of shift: quiet hours already muted non-critical; only failed Approval execution could notify.  
Weekly: Insights show overload on triple night stretches — evidence from shift density, not health metrics.

### Scenario coverage

| Scenario | How LifePilot helps |
|---|---|
| Reminders | Pre-shift packing and recovery tasks |
| Personal events | Social plans marked Personal vs Work shifts |
| Work schedules | Shift/Event model with nonstandard hours |
| Conflicts | Overlap across day-boundary shifts |
| Travel | Optional transit time before shift |
| Approvals | Reschedule personal event; never auto-text friends |

### Permissions

| Permission | Level | Notes |
|---|---|---|
| Calendar | **Necessary** | Shift source of truth |
| Reminders | Optional | Can use LifePilot-only tasks |
| Notifications | **Necessary** | With strong quiet hours |
| Location | Optional | Commute before shift |
| Background refresh | Optional | Prefer onboard when charging |
| Mail / Health | Declined by design | Out of scope |

---

## 3. Sam Rivera — Parent / caregiver

**Archetype:** Parent or caregiver coordinating family events  
**Age / context:** 41, two kids (7 and 11), dual-income household, elder parent nearby  
**Devices:** iPhone + iPad on fridge stand; partner has separate Apple ID

### Goals

- Not miss school pickup, pediatric appointments, or meds-for-parent *reminders* (not medical advice)
- See household logistics vs work meetings in one Timeline with clear context badges
- Share a plan with partner manually without LifePilot emailing anyone

### Failure modes

- Cluttered Home with stats and promos — too much cognitive load at 07:10
- Private elder-care items leak to lock screen
- Partner changes a calendar event; LifePilot stale without freshness banner

### Accessibility needs

- One-handed reach: Capture and Approvals reachable on phone
- Voice Control labels on Approve / Reject
- Dyslexia-friendly: short sentences on Briefing cards; avoid walls of text

### Trust concerns

- Children and elder details are **Private** by default when tagged
- Will not connect HealthKit; medication prompts are user-authored reminders only
- Shared school calendar is OK read-only until Approval for writes

### Day in the life

06:50 Briefing: school drop-off, work standup, pediatric follow-up, “call clinic to confirm” task.  
15:10 Reminder: pickup in 20 minutes; conflict if late meeting runs over — proposal to leave early buffer (Approval for calendar block).  
16:00 Travel: traffic optional; otherwise fixed buffer preference from Memory.  
19:30 Personal: parent’s pharmacy pickup reminder.  
20:00 Manual share: copy tomorrow’s kid schedule into Messages via share sheet — not auto-send.

### Scenario coverage

| Scenario | How LifePilot helps |
|---|---|
| Reminders | Pickup, forms, pharmacy (user-authored) |
| Personal events | School / family on Timeline |
| Work schedules | Job meetings with Work badge |
| Conflicts | Pickup vs late meeting |
| Travel | Buffer to school / clinic |
| Approvals | Hold block / move meeting proposals |

### Permissions

| Permission | Level | Notes |
|---|---|---|
| Calendar | **Necessary** | Family + work calendars |
| Reminders | **Necessary** | High reminder load |
| Notifications | **Necessary** | Time-critical pickups |
| Location | Optional | Pickup travel ETA |
| Contacts | Declined by design MVP | Manual share instead |
| HealthKit | Declined by design | Non-goal for MVP |
| Mail | Declined by design | Manual communication only |

---

## 4. Riley Santos — Founder / student

**Archetype:** Founder or student managing high context switching  
**Age / context:** 23, CS senior + weekend startup; irregular sleep; many half-finished tasks  
**Devices:** iPhone + aging MacBook; uses Quick Capture constantly

### Goals

- Brain-dump tasks without organizing up front (Inbox)
- Detect overload across classes, pitches, and social plans
- Lightweight Approvals so “add to calendar” is fast but still explicit

### Failure modes

- Abandons apps that force heavy setup
- Creates duplicate events when sync confusion strikes
- Treats Insights fake charts as truth if we show placeholders as data

### Accessibility needs

- ADHD-aware: short Briefing, clear next action, undo on complete
- Keyboard + Shortcuts on Mac for Capture
- Focus modes: respect system Focus for notification delivery

### Trust concerns

- Startup pitch calendar may be Private
- Optional AI enhancement: must stay off by default; no API keys on device
- Wary of account walls; local-only must complete all MVP workflows

### Day in the life

09:00 Capture five inbox tasks between classes.  
11:00 Briefing/Timeline: lecture, coffee chat, hackathon deadline.  
14:00 Conflict: investor call vs lab section — proposal options shown with evidence.  
18:00 Travel to meetup: optional weather.  
22:00 Insights: “three nights with <6h free before midnight events” from schedule density — not health sensing.  
Approves creating a Calendar hold for exam week.

### Scenario coverage

| Scenario | How LifePilot helps |
|---|---|
| Reminders | Deadline nudges |
| Personal events | Social + club |
| Work schedules | Classes + startup calls as Work/School |
| Conflicts | Dual-track overload |
| Travel | Meetup / campus travel prep |
| Approvals | Fast approve of holds and reminders |

### Permissions

| Permission | Level | Notes |
|---|---|---|
| Calendar | Optional → soon Necessary | Can start local-only events |
| Reminders | Optional | LifePilot tasks suffice initially |
| Notifications | **Necessary** | Or engagement collapses |
| Location | Optional | |
| Mic / Speech | Optional future | Not MVP |
| Mail / Health / Finance | Declined by design | Out of scope |

---

## 5. Morgan Ellis — Privacy-sensitive user

**Archetype:** Privacy-sensitive user who connects only selected sources  
**Age / context:** 38, freelance designer, prior workplace surveillance anxiety  
**Devices:** iPhone; Mac with firewall; no always-on location

### Goals

- Full briefing value with **Calendar only** (or reminders only)
- Inspect every external write; prefer reject over convenience
- Export and delete local data without residual cloud copies they didn’t opt into

### Failure modes

- Single bundled “enable all” onboarding → churn
- Silent background sync assumptions
- Insights that infer “sensitive” life events without clear evidence trail

### Accessibility needs

- Screen reader: every recommendation announces evidence sources and freshness
- Clear “what we accessed” wording in Settings
- No motion-only urgency indicators

### Trust concerns

- Default local-only; CloudKit strictly opt-in
- Private context + Privacy Lock for Search
- No Mail, Health, Mic, Contacts, Photos
- AI features remain disabled; never sends calendar bodies to a model without explicit future opt-in (post-MVP gate)

### Day in the life

Onboarding: skips Location, skips account, connects Calendar, denies Reminders initially.  
Morning: Briefing from Calendar + LifePilot tasks only; travel section hidden (permission denied → reduced copy).  
Midday: Proposal to create a Reminder — Morgan rejects until connecting Reminders later in Settings.  
Evening: Reviews Approvals history audit. Exports data, verifies Private notes excluded.  
Uses share sheet if they want a human to know a plan — LifePilot never emails.

### Scenario coverage

| Scenario | How LifePilot helps |
|---|---|
| Reminders | Local tasks until Reminders optionally connected |
| Personal events | Calendar read; writes via Approval only |
| Work schedules | Client calls tagged Work |
| Conflicts | Shown with calendar evidence only |
| Travel | Graceful absence without Location |
| Approvals | Primary daily habit; high reject rate is OK |

### Permissions

| Permission | Level | Notes |
|---|---|---|
| Calendar | Optional but usual choice | May use local events only |
| Reminders | Optional | Connect later |
| Notifications | Optional → recommended | Can check app manually |
| Location | Declined by design | |
| CloudKit / account | Declined by design until trust earned | |
| Mail / Health / Contacts / Mic | Declined by design | Out of scope |

---

## Cross-persona scenario matrix

| Scenario | Avery | Jordan | Sam | Riley | Morgan |
|---|---|---|---|---|---|
| Reminder prep before commitment | Y | Y | Y | Y | Y (local) |
| Personal event on Timeline | Y | Y | Y | Y | Y |
| Work / shift schedule | Y | Y | Y | Y | Y |
| Conflict + approval to fix | Y | Y | Y | Y | Y |
| Travel / weather optional | Y | Y | Y | Y | Graceful deny |
| Manual communication / share | Y | Y | Y | Y | Y |
| Auto email send | Never | Never | Never | Never | Never |

---

## Design implications (for issues #28–#33)

1. Briefing must support shift-oriented days (Jordan), not only mornings (Avery/Sam).
2. Quiet hours and sensitive notification previews are MVP-critical (Jordan/Sam/Morgan).
3. Capture + Inbox empty states serve Riley; must not require Calendar first.
4. Approvals need exhausted-user ergonomics and VoiceOver completeness.
5. Honest empty Insights — never fake charts for Riley/Morgan trust.

---

## Acceptance criteria checklist (issue #25)

- [x] At least five named personas are documented (exactly five: Avery, Jordan, Sam, Riley, Morgan)
- [x] Each persona includes goals, failure modes, accessibility needs, trust concerns, and a day-in-the-life scenario
- [x] Scenarios cover reminders, personal events, work schedules, conflicts, travel, communication (manual share — not email auto-send), and approvals
- [x] Personas identify which data permissions are optional versus necessary (and declined-by-design)
- [x] Coverage includes busy professional, shift worker, parent/caregiver, founder/student, privacy-sensitive user
- [x] Scope excludes finance, HealthKit medical MVP, and Mail auto-send
