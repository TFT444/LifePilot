# Design System

LifePilot's design system is the shared visual and interaction language every feature is built from. It lives in code under [`DesignSystem/`](../DesignSystem/) and in brand assets under [`Assets/brand/`](../Assets/brand/); this document is the rationale and reference for both.

## Principles

1. **Calm by default.** LifePilot delivers information proactively; it should never feel like it's shouting. Motion, color, and density are used sparingly and purposefully.
2. **Explanation is a first-class UI element.** Every recommendation surface must have room for the "why," not just the "what" — see [Core Philosophy](../README.md#core-philosophy).
3. **One system, every surface.** iOS, macOS, and the future web dashboard draw from the same tokens, so LifePilot feels like one product wherever it's used.
4. **Accessible by construction.** Dynamic Type, VoiceOver, and sufficient contrast are requirements, not follow-up work — see [Engineering Guide](ENGINEERING_GUIDE.md#accessibility).

## Brand Mark

The LifePilot mark — the "L" merging into a circular swoosh around a sparkle — represents the product's core idea: fragmented signals (the open arc) resolving into one clear point of understanding (the sparkle). The source file is [`Assets/brand/logo.svg`](../Assets/brand/logo.svg); see [`Assets/brand/README.md`](../Assets/brand/README.md) for usage rules and how derived icon sizes are generated. Never redraw the mark from a screenshot — always derive from the source SVG.

## Color

| Token | Value | Usage |
|---|---|---|
| `color.background.primary` | `#05050F` (dark) / `#FFFFFF` (light) | App background |
| `color.background.elevated` | `#0A0A1A` (dark) / `#F5F5F7` (light) | Cards, sheets |
| `color.accent.primary` | `#7C3AED` → `#2563EB` gradient | Primary actions, brand moments |
| `color.text.primary` | `#FFFFFF` (dark) / `#111114` (light) | Primary text |
| `color.text.secondary` | `#9CA3C4` (dark) / `#6B7280` (light) | Secondary text, captions |
| `color.signal.risk` | `#E94560` | Conflicts, warnings, high-risk actions |
| `color.signal.success` | `#2EA44F` | Confirmed, approved, completed states |

Color tokens are defined once in `DesignSystem/Tokens/Color.swift` and referenced by name everywhere else — no feature module should hardcode a hex value.

## Typography

| Style | Weight | Size (pt) | Usage |
|---|---|---|---|
| `title.large` | Bold | 34 | Screen titles |
| `title.medium` | Semibold | 22 | Section headers |
| `body` | Regular | 17 | Primary content |
| `caption` | Medium | 13 | Metadata, timestamps |

Typography uses the system font (SF Pro) and scales with Dynamic Type by default — see [Accessibility](ENGINEERING_GUIDE.md#accessibility).

## Spacing

An 8pt base grid: `spacing.xs` (4), `spacing.sm` (8), `spacing.md` (16), `spacing.lg` (24), `spacing.xl` (32). Components should compose from these tokens rather than introducing one-off values.

## Components

Core components live in `DesignSystem/Components/`, each with a preview target and a corresponding entry in `Examples/`:

| Component | Purpose |
|---|---|
| `BriefingCard` | Summarized unit of the Morning Briefing |
| `TimelineRow` | A single chronological entry in the Timeline |
| `ApprovalSheet` | Presents a recommended action with reasoning and approve/dismiss controls |
| `SignalBadge` | Small indicator for risk, success, or informational signals |
| `AgentAvatar` | Visual identity for a given AI agent's output |

## Theming

Light and dark themes are both first-class — not an inverted afterthought. Every token above has an explicit value in both modes, validated in CI via snapshot tests (see [Testing Strategy](ENGINEERING_GUIDE.md#testing-strategy)).

## Motion

Motion communicates causality — a card animating in should suggest *why* it appeared (e.g. a new signal was observed), not just draw attention. Default transitions are short (150–250ms) and use standard easing; anything longer needs a specific justification tied to what it's communicating.

## Status

The design system is being built out in **Phase 2** of the [Roadmap](../ROADMAP.md#phase-2--design-system). This document will grow alongside `DesignSystem/` as components are implemented — treat the tables above as the current source of truth, updated in the same PR as any token or component change.
