# LifePilot MVP Scope

**Issue:** [#26](https://github.com/TFT444/lifepilot/issues/26)  
**Status:** Signed off for daily-life MVP planning (2026-07-15)  
**Owner:** Product + engineering (solo maintainer workflow)  
**Scope baseline:** [`docs/IMPLEMENTATION_STATUS.md`](../IMPLEMENTATION_STATUS.md), [`.cursor/rules/lifepilot-mvp.mdc`](../../.cursor/rules/lifepilot-mvp.mdc), [`PERSONAS.md`](PERSONAS.md), [`INFORMATION_ARCHITECTURE.md`](INFORMATION_ARCHITECTURE.md)

This document turns the long-term “AI OS for everyday life” vision into a **shippable first product** with hard boundaries. Post-beta and platform ideas may be discussed, but they **cannot enter the MVP milestone** without an explicit scope change recorded here and in IMPLEMENTATION_STATUS.

---

## 1. MVP one-liner

LifePilot MVP is an **offline-first daily planner** that unifies tasks, reminders, personal/work events and shifts into a Today briefing and Timeline, detects conflicts and preparation gaps, and applies **approval-gated** writes to Calendar/Reminders/Notifications — with explainable evidence, least-privilege permissions, and no finance, health-MVP, or mail-auto-send surfaces.

---

## 2. Must-have MVP workflows

| ID | Workflow | User outcome | Depends on |
|---|---|---|---|
| W1 | First launch & progressive onboarding | Local-first ready; permissions optional/skippable | #29, #35 |
| W2 | Quick capture task / reminder / local event draft | Captured from any root surface | #28, #36 |
| W3 | Task lists (Inbox / Today / Upcoming / Completed) | CRUD, tags, subtasks, recurrence model | Stage 4 eng |
| W4 | Unified Timeline (day) | Events, shifts, due tasks in one chronology | Stage 5 eng |
| W5 | Morning / anytime Briefing | Ranked, explainable prep from stores + planning | Stage 6 eng |
| W6 | Conflict & buffer detection | Overlap / travel buffer / work-hours / overload surfaced | Stage 5 eng |
| W7 | Recommendations → Approvals → Execute | Explicit approve/reject/edit; revalidate; audit | Stage 7 eng, #28 |
| W8 | Memory & preferences | User-visible preferences shaped by corrections | Stage 8 eng |
| W9 | Insights (evidence-only) | Patterns with sources; honest empty states | Stage 8 eng |
| W10 | Offline search | Find local + cached entities | Stage 8 eng, IA Search |
| W11 | Settings: permissions, privacy, export, delete | Least privilege; user data control | #35, Stage 8 |
| W12 | Graceful Calendar / Reminders / Notifications adapters | Read when allowed; writes only via Approval | Stage 9 eng |
| W13 | Freshness / offline / permission-denied UI | Never silent stale or trapped denial | #38, IA recovery |
| W14 | Accessibility baseline | Dynamic Type, VoiceOver, Reduce Motion on core flows | #33 |

Optional but in-MVP if time: WeatherKit / MapKit **read-only** prep when Location granted (degrades if not).

---

## 3. Explicit non-goals (MVP)

| Non-goal | Rationale |
|---|---|
| **Autonomous execution** without Approval | Trust principle; Security architecture |
| **Finance / banking / spending / bills / shopping** | Permanent product exclusion |
| **HealthKit / medical intelligence** | Deferred; not shipping MVP |
| **Apple Mail ingestion** | Out of scope |
| **Automatic message / email send** | Communication is manual share/copy only |
| **Client-embedded AI API secrets** | AI optional, disabled by default, protocol-only |
| **Multi-user family accounts / chat** | Shared = metadata/context badge only |
| **Widgets / App Intents richness** | Stage 11 after core flows |
| **Fake Charts / vanity Insights** | Placeholder OK; fabricated metrics not OK |
| **Replacing Calendar or Reminders as SOR** | Orchestrate, don’t fork |

Anything in this table appearing in a PR is a **scope regression** (see APPROVAL_POLICY.md).

---

## 4. Horizon buckets

### 4.1 MVP (ship bar)

- Workflows W1–W14 above
- IA destinations for Home, Timeline, Tasks, Approvals, Memory, Insights, Search, Settings, recovery ([INFORMATION_ARCHITECTURE.md](INFORMATION_ARCHITECTURE.md))
- Persona-validated journeys ([PERSONAS.md](PERSONAS.md), #28)
- In-memory → SwiftData offline persistence (#34) with launch persistence (#35)
- Protocolized services + mocks (#37)
- Design tokens / wireframes / a11y standards (#30–#33) as needed to implement, not as infinite polish gate

### 4.2 Post-beta (after MVP reliability)

- Rich Widgets and App Intents (Stage 11)
- Optional CloudKit additive sync hardening
- Optional on-device / user-keyed AI enhancement with clear disclosure
- Week Timeline density tools beyond MVP day view
- Advanced recurrence editors; natural-language capture
- Usability validation rounds beyond initial five sessions (#32 continuation)
- macOS menu-bar / multi-window polish beyond sidebar parity

### 4.3 Platform (long-term roadmap)

- Broader agent ecosystem and third-party capability APIs
- User-defined automation rules (still scoped, opt-in, approval tiers)
- Cross-device presence beyond optional CloudKit
- Mail/health/finance domains only if product strategy **explicitly** revisits non-goals (not silent)
- “Life OS” shell that opens system apps less often (vision doc)

Post-MVP ideas must open a new issue tagged `phase: post-beta` or `phase: platform` — they must not be filed under the MVP milestone without editing this document.

---

## 5. Success metrics

All thresholds below are **MVP north stars**. Instrument what is feasible offline/on-device first; server analytics are optional and must be privacy-reviewed.

### 5.1 Activation

| Metric | Definition | MVP threshold |
|---|---|---|
| **Activated user** | Completes onboarding (or skip) and creates ≥1 task **or** connects Calendar **or** completes ≥1 Briefing view with non-empty local day | ≥60% of installs that open app twice |
| **Time-to-value** | Median minutes from first open to first useful Briefing or Timeline with content | ≤10 minutes |
| **Permission without trap** | Users who deny Calendar can still capture tasks and see Home | 100% of denial paths usable (qualitative QA gate) |

### 5.2 Retention

| Metric | Definition | MVP threshold |
|---|---|---|
| **D1 / D7 open** | Distinct days app opened | D1 ≥40%, D7 ≥20% of activated (directionally; small-n OK in beta) |
| **Briefing habit** | Activated users who open Home/Briefing on ≥3 distinct days in first week | ≥35% |
| **Churn signal** | Uninstall or permissions all revoked within 48h after unexpected external write | Target ≈0; any incident is P0 |

### 5.3 Briefing usefulness

| Metric | Definition | MVP threshold |
|---|---|---|
| **Useful briefing** | User does not dismiss entire briefing as useless; or qualitatively rates “helped me prepare” in beta survey | ≥70% of survey responses ≥4/5 |
| **Evidence coverage** | Share of recommendations showing evidence + freshness + reason | 100% |
| **Stale presentation** | Briefing shown without freshness/partial banner when data known stale | 0 tolerance in QA |

### 5.4 Approval accuracy

| Metric | Definition | MVP threshold |
|---|---|---|
| **Approve rate** | Approvals approved without edit | Monitor; healthy band ~40–75% (not a vanity maximize) |
| **Edit rate** | Approved after user edit | Track; high edit → proposal quality issue |
| **Reject-with-reason → Memory** | Rejects that create/update preference | ≥50% of explicit “don’t do this” rejects |
| **Bypass writes** | External mutations without Approval path | **0** (security tests + code review) |
| **Revalidation catches** | Stale proposals blocked at execute | 100% of fixture cases |

### 5.5 Reliability

| Metric | Definition | MVP threshold |
|---|---|---|
| **CI green** | Build, Lint, Format, Unit Tests on `develop` heads | Required to merge |
| **Crash-free sessions** | Beta | ≥99.5% |
| **Idempotent execute** | Double-approve / retry does not duplicate external write | 100% unit/integration cases |
| **Offline task CRUD** | Create/edit/complete with network off | 100% QA |

### 5.6 Privacy

| Metric | Definition | MVP threshold |
|---|---|---|
| **Least privilege** | No permission prompt without preceding education screen | 100% flows |
| **Skip-safe** | Every permission skippable | 100% |
| **Private redaction** | Private context redacted on lock screen by default | 100% QA |
| **Export / delete** | User can export and delete LifePilot-owned data | Shipped in Settings |
| **No forbidden scopes** | Finance/Health MVP/Mail auto-send surfaces | Regression scan clean |
| **No secrets in client** | API keys in repo/app | 0 |

---

## 6. Feature → issue / engineering map

### 6.1 Product docs / design (issues #24–#33)

| Issue | MVP role | Map to workflows |
|---|---|---|
| [#24](https://github.com/TFT444/lifepilot/issues/24) IA | Navigation destinations | All |
| [#25](https://github.com/TFT444/lifepilot/issues/25) Personas | Validation targets | All |
| [#26](https://github.com/TFT444/lifepilot/issues/26) This scope | Gate for milestones | All |
| [#27](https://github.com/TFT444/lifepilot/issues/27) Repo reconciliation | Unblock trustworthy develop | Eng hygiene |
| [#28](https://github.com/TFT444/lifepilot/issues/28) Journeys | Happy + recovery paths | W1–W8, W13 |
| [#29](https://github.com/TFT444/lifepilot/issues/29) Onboarding / permissions UX | Education before prompts | W1, W11 |
| [#30](https://github.com/TFT444/lifepilot/issues/30) Tokens / responsive | Phone + Mac IA adaptations | W1–W14 |
| [#31](https://github.com/TFT444/lifepilot/issues/31) Wireframes | Screen coverage before code expansion | All destinations |
| [#32](https://github.com/TFT444/lifepilot/issues/32) Hi-fi prototype | Usability with personas | Post-wireframe validation |
| [#33](https://github.com/TFT444/lifepilot/issues/33) A11y / notification / sensitive content standards | W14 + privacy metrics | W7, W11, W14 |

### 6.2 Engineering foundation (issues #34–#38)

| Issue | MVP role | Map to workflows |
|---|---|---|
| [#34](https://github.com/TFT444/lifepilot/issues/34) SwiftData offline model | Persist LifePilot-owned state | W2–W11, W13 |
| [#35](https://github.com/TFT444/lifepilot/issues/35) Launch / onboarding / settings persistence | Stop onboarding loops | W1, W11 |
| [#36](https://github.com/TFT444/lifepilot/issues/36) Typed navigation / deep links / capture | Routes match IA | W2, W7, notifications |
| [#37](https://github.com/TFT444/lifepilot/issues/37) Service protocols / errors | Features → protocols only | W12, tests |
| [#38](https://github.com/TFT444/lifepilot/issues/38) UI state / fixtures / feature tests | Loading/empty/offline/failure patterns | W13, W14 |

### 6.3 Existing engineering work (IMPLEMENTATION_STATUS)

| Stage | Status (2026-07-15) | MVP workflows |
|---|---|---|
| 1 Audit / rules / status | Done | Governance |
| 2 Scope correction (finance out) | Done | Non-goals enforced |
| 3 Domain contracts + in-memory stores | Mostly done; SwiftData adapter pending (#34) | W3–W8 |
| 4 Tasks / reminders / notification protocol | Done (no-op scheduler) | W2, W3 |
| 5 Events / conflicts / Timeline | Done (store-backed) | W4, W6 |
| 6 Store-backed Briefing UI | **Open** | W5 |
| 7 Approvals executor + UI | Core done; AppShell bypass review open | W7 |
| 8 Memory / Insights / Search / privacy UI | Partial | W8–W11 |
| 9 System adapters EventKit etc. | **Open** | W12 |
| 10 Optional AI boundary | Documented disabled | Non-goal autonomous AI |
| 11 Intents / widgets | After core | Post-beta |
| 12 A11y / docs / CI | In progress | W14, reliability |

Primary implementation branch: `cursor/daily-life-mvp-4d5a` / PR [#39](https://github.com/TFT444/lifepilot/pull/39).

---

## 7. MVP milestone exit checklist

A build may be called “daily-life MVP” only when:

1. W1–W14 work for the five personas on phone; Mac sidebar reaches Home, Timeline, Tasks, Approvals, Insights, Settings.
2. Zero external writes bypass Approval; security tests green.
3. Offline task/preference/approval persistence survives relaunch (#34/#35).
4. Calendar/Reminders denial still yields a usable app.
5. Regression scan: no finance/shopping/HealthKit-MVP/Mail-auto-send.
6. CI green on the release branch head.
7. Docs (IA, Personas, this scope, IMPLEMENTATION_STATUS) match shipped behavior — no screenshot-as-implementation.

---

## Acceptance criteria checklist (issue #26)

- [x] A signed-off MVP scope is committed (`docs/product/MVP_SCOPE.md`, dated 2026-07-15)
- [x] Every MVP feature maps to a roadmap issue (#24–#38) and/or IMPLEMENTATION_STATUS stages (§6)
- [x] Success thresholds have measurable definitions (§5)
- [x] Post-MVP ideas cannot silently enter the MVP milestone (§4 buckets + process note)
- [x] Non-goals explicitly include autonomous execution, finance, health MVP, and mail send (§3)
