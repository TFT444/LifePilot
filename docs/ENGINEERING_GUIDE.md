# Engineering Guide

This document covers how LifePilot is engineered day to day: architectural patterns, testing strategy, error handling, logging, accessibility, localization, and performance standards. For repository-level structure, see [ARCHITECTURE.md](ARCHITECTURE.md). For Swift syntax and formatting conventions, see [STYLE_GUIDE.md](STYLE_GUIDE.md).

## Table of Contents

- [Architectural Pattern: MVVM](#architectural-pattern-mvvm)
- [Dependency Injection](#dependency-injection)
- [Testing Strategy](#testing-strategy)
- [Error Handling](#error-handling)
- [Logging](#logging)
- [Accessibility](#accessibility)
- [Localization](#localization)
- [Performance](#performance)
- [Release Strategy](#release-strategy)

## Architectural Pattern: MVVM

LifePilot's `Features` layer follows MVVM (Model-View-ViewModel):

- **Model** — plain data types from `Core`, with no knowledge of presentation.
- **ViewModel** — owns presentation state and logic, exposes it via `@Observable` (or `ObservableObject` where targeting earlier OS versions), and talks to `Core`/`Agents` through injected protocols.
- **View** — SwiftUI views that render ViewModel state and forward user intent back to it. Views never call into `Services` or `Agents` directly.

```swift
// Features/MorningBriefing/MorningBriefingViewModel.swift
@Observable
final class MorningBriefingViewModel {
    private let ghostBrain: GhostBrainProviding

    private(set) var briefing: Briefing?

    init(ghostBrain: GhostBrainProviding) {
        self.ghostBrain = ghostBrain
    }

    func load() async {
        briefing = try? await ghostBrain.prepareBriefing()
    }
}
```

ViewModels are constructed with their dependencies (see [Dependency Injection](#dependency-injection)) rather than reaching for singletons, which keeps them testable without standing up the full app.

## Dependency Injection

LifePilot uses constructor injection throughout — no service locators, no global singletons for anything that has meaningful behavior or state.

- Protocols are defined in the layer that *consumes* them (e.g. `Core` defines `CalendarReading`, and `Services` provides a concrete `EventKitCalendarReader` conforming to it), following the Dependency Inversion Principle.
- A lightweight composition root in `App/` wires concrete implementations to their protocols at app launch.
- Tests substitute lightweight fakes or mocks conforming to the same protocols — no test ever talks to a real network, disk, or system framework unless it's explicitly an integration test (see below).

## Testing Strategy

Tests live under `Tests/`, mirroring the structure of the module they cover (`Tests/Core/`, `Tests/Agents/CalendarAgent/`, etc.).

| Layer | Test type | Tooling |
|---|---|---|
| `Core`, `Agents` | Unit tests — pure logic, no I/O | Swift Testing / XCTest |
| `Services` | Unit tests against protocol boundaries; integration tests against real SDKs, run separately from the default suite | XCTest |
| `Features` | ViewModel unit tests; snapshot tests for critical UI states | XCTest, snapshot-testing |
| `DesignSystem` | Snapshot tests, in both light and dark theme | snapshot-testing |

**Standards:**

- New logic requires new or updated tests in the same PR — see the [Pull Request checklist](../CONTRIBUTING.md#pull-request-process).
- Agents are tested with the Ghost Brain mocked as a plain context object; the Ghost Brain is tested with agents mocked to return fixed predictions. Neither is tested only in combination — see [AI Agent Architecture](ARCHITECTURE.md#ai-agent-architecture).
- Flaky tests are treated as bugs, not skipped — a skipped test is tracked as a `type: bug` issue, not silently ignored.
- CI runs the full suite with code coverage on every Pull Request (see [`.github/workflows/test.yml`](../.github/workflows/test.yml)).

## Error Handling

- Use typed `Error` enums per domain (e.g. `CalendarAgentError`) rather than passing `String` or generic `NSError` across module boundaries.
- Errors that a user can act on should carry enough context to explain *and* recover — consistent with the product's [Explain](../README.md#core-philosophy) principle extending into error states.
- Never swallow an error silently (`try?` without a comment justifying why failure is safe to ignore). Log it, surface it, or propagate it.
- Integration-layer failures (a connected app is unreachable) must degrade gracefully — the Ghost Brain should reason with partial data rather than failing the entire briefing.

## Logging

- Use a structured logging facade (`Services/Logging`) rather than `print()`. Every log line carries a subsystem and category (e.g. `subsystem: "com.lifepilot.agents", category: "CalendarAgent"`).
- Log levels: `debug` (local development only), `info` (lifecycle events), `error` (recoverable failures), `fault` (unexpected/unrecoverable state).
- **Never log personally identifiable content** — event titles, email bodies, contact names — even at `debug` level. Log structural information (`"3 events fetched"`, not the events themselves). This is a direct extension of the [privacy-first architecture](../SECURITY.md#our-philosophy).

## Accessibility

Accessibility is a requirement, not a follow-up pass:

- All interactive elements have accurate accessibility labels and traits.
- Layouts support Dynamic Type up to at least the `accessibility3` size category without truncation or overlap.
- Color is never the sole carrier of meaning (e.g. risk signals pair color with an icon and text, not color alone).
- VoiceOver navigation order is verified manually for any new screen before merge.

## Localization

- All user-facing strings live in `Resources/Localizable.xcstrings` — no string literals in `Features` or `DesignSystem` view code.
- Dates, times, and numbers are formatted with `Foundation`'s locale-aware formatters, never hand-built strings.
- English is the source language through Phase 8; additional locales are prioritized starting in **Phase 9 — Public Beta** (see [Master Roadmap](../MASTER_ROADMAP.md#phase-9--public-beta)) based on beta cohort composition.

## Performance

- Launch time, scroll performance, and memory footprint are measured with Instruments before and after any change touching `Features` or `DesignSystem` hot paths.
- The Ghost Brain's fusion step must remain non-blocking on the main actor — long-running reasoning runs off the main thread and reports back via `async`/`await`.
- Regressions are reported using the [Performance Issue template](../.github/ISSUE_TEMPLATE/performance_issue.yml), with measured before/after data, not impressions.

## Release Strategy

LifePilot uses [Semantic Versioning](https://semver.org/) (`MAJOR.MINOR.PATCH`), mapped to the [Master Roadmap](../MASTER_ROADMAP.md#milestone-table) as follows:

| Version | Milestone |
|---|---|
| `v0.1.0` | Repository Foundation |
| `v0.2.0` | Product Foundation |
| `v0.3.0` | Design System |
| `v0.4.0` | SwiftUI Foundation |
| `v0.5.0` | Core Product |
| `v0.6.0` | Ghost Brain |
| `v0.7.0` | AI Agents |
| `v0.8.0` | Platform Integrations |
| `v0.9.0` | Testing & Quality |
| `v0.10.0` | Public Beta |
| `v1.0.0`+ | LifePilot Platform |

- **MAJOR** — breaking changes to public APIs or data models.
- **MINOR** — new functionality, backward compatible.
- **PATCH** — bug fixes, no functional change to public behavior.

Releases are cut from `main` and tagged (`vX.Y.Z`), triggering [`.github/workflows/release.yml`](../.github/workflows/release.yml). See [Branch Strategy](../README.md#branch-strategy) for how code reaches `main`, and [CHANGELOG.md](../CHANGELOG.md) for the human-readable history of each release.
