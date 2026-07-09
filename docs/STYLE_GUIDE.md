# Style Guide

Conventions for writing Swift in the LifePilot codebase. Enforced automatically by SwiftLint and SwiftFormat in CI (see [`.github/workflows/lint.yml`](../.github/workflows/lint.yml)) — this document explains the *why* behind the rules the linter enforces mechanically.

## Table of Contents

- [Swift Style Guide](#swift-style-guide)
- [Folder Organization](#folder-organization)
- [Naming Conventions](#naming-conventions)

## Swift Style Guide

### Formatting

- 4-space indentation, no tabs.
- 120-character line length soft limit.
- One type per file, named identically to the file (`CalendarAgent.swift` contains `CalendarAgent`).
- Imports sorted alphabetically, system frameworks before first-party modules.

### Language Features

- Prefer `struct` over `class` unless reference semantics or identity are explicitly required.
- Prefer `let` over `var`; mutability should be visible and intentional.
- Use `guard` for early returns over nested `if`.
- Avoid force-unwrap (`!`) and force-try (`try!`) outside of tests and `Preview` providers. If a value is truly guaranteed non-nil, prefer expressing that in the type system over asserting it at the call site.
- Use Swift Concurrency (`async`/`await`, actors) over completion handlers or Combine for new code — see [API Guidelines](API_GUIDELINES.md#async-by-default).
- Mark types `final` unless designed for subclassing.

### Documentation Comments

Public types and non-obvious logic get a `///` doc comment explaining intent, not restating the signature:

```swift
/// Fuses predictions from every registered agent into a single, ranked
/// model of the day. Cross-agent conflicts (e.g. two agents proposing
/// contradictory actions) are resolved here, not in individual agents.
struct GhostBrain { ... }
```

Avoid comments that restate what the code already says — see the project-wide guidance on writing no unnecessary comments; this applies to `///` docs too.

### SwiftUI Conventions

- Views are structs, kept small; extract subviews rather than growing a single `body`.
- No business logic in `View` bodies — delegate to the ViewModel (see [MVVM](ENGINEERING_GUIDE.md#architectural-pattern-mvvm)).
- Use semantic design tokens from `DesignSystem`, never raw colors, fonts, or spacing values — see [Design System](DESIGN_SYSTEM.md).

## Folder Organization

Within any module (`Core`, `Agents`, `Features`, etc.), organize by feature, not by file type:

```
Agents/CalendarAgent/
├── CalendarAgent.swift
├── CalendarSignal.swift
├── CalendarPrediction.swift
└── CalendarAgentTests.swift   # or mirrored under Tests/, per module convention
```

Not:

```
Agents/
├── Models/
├── Views/
└── Controllers/
```

Feature-oriented organization keeps related code discoverable together and makes module boundaries (see [ARCHITECTURE.md](ARCHITECTURE.md#dependency-rules)) easier to enforce, since a whole feature can be reviewed, moved, or extracted as a unit.

## Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Types | `UpperCamelCase` | `CalendarAgent`, `BriefingCard` |
| Functions, variables | `lowerCamelCase` | `prepareBriefing()`, `activeSignals` |
| Protocols (capability) | Adjective / gerund phrase | `CalendarReading`, `ApprovalGating` |
| Booleans | `is`/`has`/`should` prefix | `isApproved`, `hasConflict` |
| Constants | `lowerCamelCase`, scoped, never global mutable state | `static let maxRetryCount = 3` |
| Design tokens | `category.subcategory.variant` | `color.signal.risk`, `spacing.md` |

Agent names always end in `Agent` (`TravelAgent`, not `Travel`); signal and prediction types are named after what they describe, not the agent that produced them (`FlightDelaySignal`, not `TravelAgentSignal`) — this keeps types meaningful if agent boundaries are later reorganized.
