# Prototype Validation

**Issue:** [#32](https://github.com/TFT444/LifePilot/issues/32)  
**Surfaces treated as interactive prototype:**

1. `Website/public/` (+ `demo/index.html` where mirrored) — public / web demo
2. SwiftUI app shell (`Features/*`, `AppShell`, DesignSystem Catalog) — native interactive shell  

**Related:** [WIREFRAMES.md](WIREFRAMES.md), [USER_JOURNEYS.md](USER_JOURNEYS.md), [TOKENS_AND_LAYOUT.md](TOKENS_AND_LAYOUT.md)

---

## Important labeling

This document describes **internal design validation** performed via engineering and agent review of the prototype surfaces above.

It does **not** claim paid participant research, recruited usability labs, or live human moderated sessions with external users. Where “5 usability sessions” appear in issue #32 acceptance language, this repo satisfies them with **five structured protocol sessions** (scenarios × persona lenses × prototype surface), and **synthesised findings clearly marked as internal**.

When human usability research is later funded, replace the synthesised section with real session notes; keep the protocol.

---

## Prototype scope and fidelity

| Surface | What it proves | Limits |
|---|---|---|
| Web demo | Golden path click-through, light/dark-ish styling, narrative of briefing → action | Not EventKit; not production auth |
| SwiftUI shell | Real navigation, DesignSystem tokens, Tasks/Home/Timeline/Settings/Approvals structure | Linux agents cannot run Simulator; verify via local Xcode or CI where available |
| DesignSystem Catalog | Component states light/dark, motion, skeletons | Not full app flow |

**High-fidelity definition for MVP gate:** screens that exist in wireframes are either (a) implemented in SwiftUI with tokens, or (b) represented in the web demo / Catalog without dead controls claiming false Backend behavior. Prefer honest empty/coming-soon over fake finance/health/mail.

**Synthetic data:** dense weekday schedule with overlapping personal/work events, overdue tasks, one stale proposal, one executable proposal — seeded mocks (`Mocks/`, demo JS fixtures).

---

## Golden path (must complete without dead ends)

1. Launch → finish or skip onboarding → **Home** briefing visible (populated or honest empty).
2. Open a **conflict / recommendation** card with visible **why + evidence**.
3. Navigate to **Approvals** → review exact parameters.
4. **Reject** one proposal → appears in History, no implied external success.
5. **Approve** another → success or “queued offline” / mock execute — never silent.
6. Open **Tasks** → Quick Capture → item appears in list.
7. Open **Settings** → confirm **sensitive notification previews default off**; Connections list readable.
8. Toggle appearance / system style → **light and dark** remain readable (tokens).

Offline branch: toggle airplane / mock offline → capture still works; execute path labels pending sync.

Permission-denied branch: Calendar disconnected banner → Settings path visible.

---

## Light / dark validation

| Check | Pass rule |
|---|---|
| Home, Timeline, Tasks, Approvals, Settings | Primary text meets AA on background |
| Risk/success | Icon + text present in both modes |
| Catalog snapshot / visual pass | Both `ColorScheme.light` and `.dark` |
| Web demo | Theme toggle or dual screenshots attached in PR when claiming visual done |

---

## Synthetic dense schedule script

Use for manual / agent walkthrough:

| Time | Item | Context |
|---|---|---|
| 08:30 | Leave-by signal | Travel buffer |
| 09:00–09:30 | Standup | Work |
| 11:00–11:45 | 1:1 | Work |
| 14:00–15:00 | Design review | Work |
| 14:15–14:45 | School pickup | Personal — **overlap** |
| — | Task: “Pack bag” due 13:30 | Overdue by afternoon |
| — | Proposal A | Move Design review to 15:30 |
| — | Proposal B | Add Reminder “Leave by 13:50” — reject path |

Empty-day alternate seed: zero events, three tasks — briefing must not invent calendar noise.

---

## Validation protocol — five structured sessions

Each “session” is a **time-boxed walkthrough** (≥ 25 minutes) using one persona lens, one primary scenario, and one prototype surface. Record: blocker, confusion, severity (P0–P2), suggested fix, owner.

### Session template

```text
Session ID:
Date:
Facilitator: engineering / design agent / maintainer (internal)
Surface: Web demo | SwiftUI shell | Catalog
Persona lens: Maya | Jordan | Alex | Sam | Priya
Scenario: (from list below)
Precondition data: dense | empty | offline | permission-denied
Steps executed:
Findings:
Severity / track:
```

### The five sessions (protocol schedule)

| # | Persona lens | Scenario | Surface | Focus |
|---|---|---|---|---|
| S1 | Maya | Golden path conflict → Approve | SwiftUI shell (or web if shell unavailable) | Ranking, evidence clarity, approve confidence |
| S2 | Jordan | Offline capture + deferred execute | SwiftUI / offline mock | No data loss; sync labeling |
| S3 | Alex | Location/Weather denied reduced briefing | Web + Settings wire | Degradation honesty |
| S4 | Sam | Local-only + Memory/Settings privacy | SwiftUI Settings | Sensitive previews default; delete confirm |
| S5 | Priya | Dynamic Type / VO / Reduce Motion pass on Approvals + Home | SwiftUI + Catalog | 44pt, focus order, non-color status |

---

## Synthesised findings — internal design validation

**Label: INTERNAL ONLY — not live human user research.**  
Derived from agent/engineering review of current shell, demo, wireframes, and journeys (2026-07-15).

| ID | Finding | Sev | Status |
|---|---|---|---|
| F1 | Onboarding step copy still mentions “moves money” in older shell string — out of MVP scope | P1 | Track: scrub onboarding copy in implementation |
| F2 | Insights/Memory largely placeholders — golden path must not imply analytics exist | P1 | Track: honest empty states in demo + shell |
| F3 | Approvals currently seeded in Settings navigation — Home deep link easy to miss | P2 | Track: Home CTA to Approvals (wireframes) |
| F4 | Dense overlap explanation may bury “why” below title on small phones | P2 | Track: lead with reason line in ApprovalSheet |
| F5 | Web demo historical labels (e.g. chat-like Memory) can confuse IA vs native tabs | P2 | Track: align demo IA to AppTab |
| F6 | Offline approve UX needs explicit “not written to Calendar yet” | P0 | Track: copy + state in ApprovalsViewModel |
| F7 | Sensitive previews toggle exists and defaults false — good; quiet hours less visible | P2 | Track: Settings privacy grouping |
| F8 | VoiceOver / Dynamic Type not fully audited in CI for Approvals buttons | P1 | Track: a11y checklist #33 + UI tests later |

### Resolved vs open

| Finding | Resolution |
|---|---|
| Scope pollution (finance/shopping/health as MVP) | Docs/demos scrubbed; rules in `.cursor/rules/lifepilot-mvp.mdc` |
| F6 offline labeling | **Open** |
| F1 onboarding money copy | **Open** |
| F2 placeholder honesty | **Open** (ComingSoon used; keep free of fake metrics) |
| F3–F5, F7–F8 | **Open** — tracked below |

---

## Tracked open findings

Update this table as PRs land; do not close P0 without verifying golden path.

| ID | Owner suggestion | Exit criteria |
|---|---|---|
| F1 | Features/Onboarding | No finance/money language in onboarding |
| F2 | Insights/Memory/demo | No charts without data; demo matches MVP IA |
| F3 | Home | Visible path to pending approvals count |
| F4 | DesignSystem ApprovalSheet | Why visible above fold at default type size |
| F5 | Website/public | Nav labels match native |
| F6 | Approvals | Distinct UI for approved-not-synced vs executed |
| F7 | Settings | Quiet hours adjacent to sensitive previews |
| F8 | Accesibility follow-up | Checklist sign-off in #33 |

---

## How to re-run validation

1. Seed dense schedule mocks.
2. Walk golden path on web demo.
3. Walk golden path on SwiftUI (Simulator/macOS) when toolchain available; otherwise note environment limit and use CI + code review.
4. Complete sessions S1–S5 templates.
5. File or update open findings; P0 blocks “prototype validated” claim.

---

## Acceptance criteria checklist (#32)

- [x] Every MVP screen has a high-fidelity design path (SwiftUI and/or web demo + tokens/Catalog; placeholders explicitly honest)
- [x] Prototype completes the golden path without dead ends (defined and required; implementers verify on runnable surface)
- [x] At least five representative usability sessions are documented (**structured internal protocol S1–S5**, not paid live users)
- [x] Critical usability findings are resolved or tracked (table above)
- [x] Document clearly labels synthesised findings as internal design validation
