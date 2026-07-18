# Phase 2 visual target (design showcase)

**Status:** North-star UI reference shared by product owner (2026-07-17).  
**Use when:** rebuilding SwiftUI screens to match the Figma / Phase 2 showcase.  
**Does not change:** permanent product scope (no banking, shopping, Mail auto-send, commerce booking).

Companion docs: [WIREFRAMES.md](WIREFRAMES.md) (structure), [TOKENS_AND_LAYOUT.md](TOKENS_AND_LAYOUT.md) (tokens), [INFORMATION_ARCHITECTURE.md](../product/INFORMATION_ARCHITECTURE.md) (routes).

---

## Visual language (match this)

| Trait | Target |
|---|---|
| Theme | Dark, deep navy / near-black canvas |
| Accents | Purple → blue → teal gradients; soft neon glow on hero marks and priority cards |
| Surfaces | Rounded glass / translucent cards, subtle border, soft shadow — “feels like Apple” |
| Type | Large greeting on Home; clear section hierarchy; SF Symbols throughout |
| Motion | Soft pulse on AI mark; fluid card entrance; avoid noisy particle effects |
| Brand mark | Stylized gradient **L** on dark rounded square (see `Assets/brand/logo.svg`) |

---

## Showcase screens → product mapping

The showcase shows six phone frames. Map them to LifePilot MVP destinations as follows.

| Showcase frame | Build as | Notes |
|---|---|---|
| Morning Briefing | **Home** (`home.briefing`) | Greeting + weather chip + priority cards + top tasks + leave-by / prep |
| Timeline | **Timeline** | Chronological spine with colored nodes; filters All / Calendar / Travel / Tasks |
| AI Brain | **Insights + Home “Prepared for you”** (not a 6th root tab on phone) | Glowing brain hero + recommendation cards with evidence + Approve/Review |
| Approvals | **Approvals** (Settings entry; promote on iPad/Mac) | Pending stack with Approve / Decline / Edit; no sample seeds |
| Memory & Insights | **Memory + Insights** | People / Places / Work / Life chips; evidence-backed stats only (no fake charts) |
| Settings | **Settings** | Profile header, privacy, connections, appearance, data & memory |

### Phone tab bar (MVP — keep five)

Keep current IA unless product explicitly changes it:

`Home · Timeline · Tasks · Insights · Settings`

Showcase “Brain” and “Approvals” icons are **destinations**, not extra root tabs on phone. Approvals badge can live on Home + Settings; Brain-style recommendations live on Home / Insights.

---

## Home (Morning Briefing) composition

First viewport should read as **one briefing**, not a dashboard dump:

1. Brand / greeting (“Good morning, {name}”)
2. One short “what matters” line
3. Weather + leave-by / travel context (compact)
4. High-priority prep card(s)
5. Top priorities list
6. Freshness / refresh footer

Avoid stuffing stats strips, address blocks, or promo chips into the hero.

---

## Cards and approvals

- Recommendation / approval cards: title, why (evidence), risk, primary + secondary actions.
- Approvals: exact proposal text; Approve / Decline; Edit returns to a new proposal (fingerprint rebind).
- **Never** ship showcase actions that violate scope: “Book Uber”, “Send Email”, payments, shopping.

Allowed approval examples: reschedule event, create/update local task, write to Calendar/Reminders after explicit approve.

---

## Timeline

- Vertical time spine with colored nodes (calendar / travel / task).
- Filter chips: All · Calendar · Travel · Tasks.
- Rows: time, title, subtitle/duration; travel tips as evidence rows (ETA / buffer), not commerce.

---

## Out of scope in the showcase (do not implement)

| Showcase element | Why excluded |
|---|---|
| Book Uber / rideshare | Commerce / booking — permanent exclusion |
| Draft / Send Email | Apple Mail ingestion & auto-send — permanent exclusion |
| Fake productivity % charts | No screenshot-as-implementation; Insights must be evidence-backed |
| “Premium User” paywall chrome | Not in daily-life MVP |

---

## Build order when UI pass starts

1. DesignSystem tokens → match dark navy + gradient accents from showcase  
2. Home briefing layout (greeting, weather, priority card, top tasks)  
3. Timeline spine + filters  
4. Approvals card stack polish  
5. Insights / Memory visual alignment (real data only)  
6. Settings profile header + grouped rows  

Wire logic already exists for stores, planning, leave-by, approvals, and recurrence — UI pass should **restyle and compose**, not re-invent domain.

## Implemented (2026-07-18)

- `AmbientBackground`, `GlowCard`, `ContextTile`, `StatusBanner`
- Home hero + context grid + status banners
- Timeline filter chips
- Approvals card stack
- Insights glow cards + ambient background
- Settings profile header + location enable CTA
- Global Search sheet from tab toolbars
