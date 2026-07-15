# Tokens and Layout

**Issue:** [#30](https://github.com/TFT444/LifePilot/issues/30)  
**Canonical narrative:** [DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md)  
**Code source of truth:** `DesignSystem/Tokens/` and `DesignSystem/Components/`  
**Catalog:** `DesignSystem/Catalog/DesignSystemCatalogView.swift`

This document finalizes semantic tokens, themes, and responsive layout rules for the MVP. **Feature modules must compose from tokens** — no hard-coded hex, spacing, radii, or motion durations outside approved exceptions listed below.

---

## Principles (from design system)

1. Calm by default.
2. Explanation is a first-class UI element.
3. One system across iOS, macOS, and future web surfaces.
4. Accessible by construction (Dynamic Type, VoiceOver, contrast).

---

## Semantic color tokens

Defined in `DesignSystem/Tokens/Color+LifePilot.swift` as `Color.LifePilot.*`.

| Semantic token | Light | Dark | Usage |
|---|---|---|---|
| `background.primary` | `#FFFFFF` | `#05050F` | App / screen background |
| `background.elevated` | `#F5F5F7` | `#0A0A1A` | Cards, sheets, grouped surfaces |
| `text.primary` | `#111114` | `#FFFFFF` | Primary readable text |
| `text.secondary` | `#6B7280` | `#9CA3C4` | Captions, metadata |
| `accent.start` / `accent.end` | `#7C3AED` → `#2563EB` | same stops | Primary actions, brand moments (`LinearGradient.LifePilot.accent`) |
| `signal.risk` | `#E94560` | `#E94560` | Conflicts, warnings — always pair with icon + text |
| `signal.success` | `#2EA44F` | `#2EA44F` | Confirmed, approved, completed — always pair with icon + text |

### High contrast

| Mode | Rule |
|---|---|
| **System Increase Contrast** | Prefer elevated separation: text.primary on background.primary; avoid low-contrast secondary-on-elevated pairs for critical labels; risk/success may darken/lighten in a future token variant — until then, rely on icon + text labels (never color alone). |
| **High Contrast theme (product)** | When shipping an explicit “High Contrast” appearance preference, map backgrounds to pure black/white and boost secondary text toward primary for body copy. Document new token aliases in the same PR as code. |

### WCAG contrast expectations

| Pairing | Expectation |
|---|---|
| `text.primary` on `background.primary` | WCAG **AA** normal text (≥ 4.5:1); aim AAA (≥ 7:1) where practical |
| `text.secondary` on `background.primary` | WCAG **AA** (≥ 4.5:1). Documented floor in DESIGN_SYSTEM.md: **4.83:1** light mode (lowest primary pairing) |
| `text.primary` on `background.elevated` | AA |
| Text on accent gradient buttons | Use white (or tokenized on-accent) label; verify ≥ 4.5:1 against both gradient stops or solid fallback |
| Risk/success as text | Only on primary/elevated backgrounds that meet AA; do not place thin risk text on busy images |

Large text (≥ 18pt regular / 14pt bold) may use 3:1 where AA Large applies; Dynamic Type means most UI should still target 4.5:1.

**CI / review:** Snapshot light and dark; contrast regressions fail review. Components in Catalog must exercise both schemes.

---

## Typography and Dynamic Type

`Font.LifePilot` in `Typography+LifePilot.swift` — system SF Pro via `TextStyle` factories (scales natively).

| Token | Text style | Weight | Default size (approx.) | Usage |
|---|---|---|---|---|
| `title.large` | `.largeTitle` | Bold | 34pt | Screen titles |
| `title.medium` | `.title2` | Semibold | 22pt | Section headers |
| `body` | `.body` | Regular | 17pt | Primary content |
| `caption` | `.footnote` | Medium | 13pt | Metadata, timestamps |

### Rules

- Layouts support at least through **accessibility3** without truncation/overlap of critical actions ([ENGINEERING_GUIDE.md](../ENGINEERING_GUIDE.md#accessibility)).
- Prefer wrapping and vertical reflow over shrinking below readable minimums.
- Do not use fixed `Font.system(size:)` for user-readable copy; icon glyph sizing uses `IconSize`, not type tokens.

---

## Spacing

`Spacing` — 8pt base grid (`DesignSystem/Tokens/Spacing.swift`):

| Token | Value |
|---|---|
| `xs` | 4 |
| `sm` | 8 |
| `md` | 16 |
| `lg` | 24 |
| `xl` | 32 |

Screen horizontal padding default: `lg` on compact phone; `xl` or readable measure on regular/desktop.

---

## Shape

`CornerRadius`:

| Token | Value | Usage |
|---|---|---|
| `sm` | 8 | Badges, chips |
| `md` | 16 | Cards, buttons |
| `lg` | 24 | Hero, sheets |
| `full` | 999 | Avatars / true pills sparingly |

---

## Elevation and materials

`ShadowStyle.LifePilot` (`Shadow.swift`):

| Token | Role |
|---|---|
| `card` | Default elevated surface (subtle) |
| `elevated` | Higher emphasis (sheets, dragged) |

Modifiers: `.lifePilotSurface`, `.lifePilotGlass`, `.cardElevation` — see DESIGN_SYSTEM.md Modifiers.

**Reduce Transparency:** When `@Environment(\.accessibilityReduceTransparency)` is true, replace `.ultraThinMaterial` / glass with opaque `background.elevated` fills. No dependence on blur to separate layers.

---

## Iconography

`IconSize`: `sm` 20, `md` 22, `lg` 44, `xl` 56. Prefer SF Symbols. Decorative icons must not be the only status channel.

---

## Motion

`Motion` (`Motion.swift`):

| Token | Duration / feel | Use |
|---|---|---|
| `quick` | 150ms easeOut | Micro-interactions |
| `press` | 120ms | Button press |
| `standard` | 200ms easeInOut | Default transitions |
| `deliberate` | 350ms | Onboarding / tab-scale context shifts |
| `spring` | response 0.4 | New content appearance (sparingly) |
| `loading` | 1.1s repeating | Skeleton shimmer |

**Reduce Motion:** Route decorative/continuous animation through `View.lifePilotAnimation(_:reduceMotion:value:)`. Skeletons become static placeholders; no infinite loops.

---

## Themes

| Appearance | Behavior |
|---|---|
| System | Follows OS (`UserPreferences.appearance = .system`) |
| Light / Dark | Explicit token pairs — first-class, not inverted hacks |
| High contrast | Follow system Increase Contrast + future product toggle |

Light and dark are validated together in Catalog and tests.

---

## Layout: compact vs regular

| Context | Compact (iPhone portrait) | Regular (iPad / macOS width) |
|---|---|---|
| Navigation | Tab bar (`AppTab`: Home, Timeline, Tasks, Insights, Settings) | Tab bar or sidebar-equivalent; same information architecture |
| Home briefing | Single column scroll; hero greeting → prepared cards → upcoming | Optional two-column: briefing list + detail/approval pane |
| Timeline | Full-width rows | Wider measure; sticky day headers |
| Approvals | Full-screen list / sheet | List + trailing inspector for proposal detail |
| Settings | Inset grouped list | Wider form width (~600–720pt max measure) |
| Capture | Bottom field or sheet | Sheet / command-width popover |

### Breakpoints (guidance)

- Compact width &lt; ~700pt: single column.
- Regular ≥ ~700pt: allow split; keep primary actions reachable without chase.

**macOS window:** Respect minimum width that keeps 44×44pt targets and no horizontal clip of Approve/Reject.

Phone + desktop wire notes: [WIREFRAMES.md](WIREFRAMES.md#device-notes).

---

## Component token contract

| Do | Don’t |
|---|---|
| Use `Color.LifePilot`, `Font.LifePilot`, `Spacing`, `CornerRadius`, `Motion`, `IconSize`, `ShadowStyle` | Hard-code `#hex`, magic padding, one-off radii |
| Pair signals with icon + text | Color-only status |
| Use DesignSystem components (`BriefingCard`, `ApprovalSheet`, …) | Parallel one-off cards that reinvent elevation |
| Document exceptions in PR | Silent exceptions |

### Approved exceptions

1. System controls that require platform APIs (e.g. `ProgressView` tint mapped to accent token still preferred).
2. Debug / Catalog-only overlays.
3. Brand SVG assets under `Assets/brand/` (not recolored via random hex in feature code).
4. Temporary scaffolding marked `TODO(design-token)` with issue link — not for shipping MVP UI.

---

## Relationship to existing docs and code

| Concern | Doc | Code |
|---|---|---|
| Color / type / spacing rationale | DESIGN_SYSTEM.md | `Color+LifePilot`, `Typography+LifePilot`, `Spacing` |
| Motion + Reduce Motion | DESIGN_SYSTEM.md + this doc | `Motion.swift` |
| Elevation | DESIGN_SYSTEM.md | `Shadow.swift`, modifiers |
| Engineering a11y bar | ENGINEERING_GUIDE.md | Features + tests |
| Notifications privacy | ACCESSIBILITY_NOTIFICATIONS.md | `UserPreferences.sensitiveNotificationPreviews` |

When tokens change, update **DESIGN_SYSTEM.md and this file in the same PR** as `DesignSystem/Tokens/*`.

---

## Acceptance criteria checklist (#30)

- [x] Every token is documented and implemented once (tables map 1:1 to `DesignSystem/Tokens`)
- [x] Light and dark themes meet WCAG contrast expectations (AA documented; secondary floor cited)
- [x] Layouts define behavior from small iPhone through macOS window sizes
- [x] Components avoid hard-coded visual values outside approved exceptions
