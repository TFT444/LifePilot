# API Guidelines

This document covers two related surfaces: the **internal Swift API contracts** between LifePilot's modules (Core, Agents, Services), and the conventions for any **external-facing API** the project exposes as it grows toward the web dashboard and third-party integrations described in [Phase 10](../MASTER_ROADMAP.md#phase-10--lifepilot-platform).

## Internal Module APIs

### Protocol-First Design

Every cross-module dependency is expressed as a protocol, owned by the consuming layer, per the [Dependency Rules](ARCHITECTURE.md#dependency-rules).

```swift
// Defined in Core, consumed by Agents and Services
protocol CalendarReading {
    func events(on date: Date) async throws -> [CalendarEvent]
}
```

- Protocol names describe capability, not implementation (`CalendarReading`, not `EventKitService`).
- Concrete implementations live in `Services` or `Integrations`, named after what they wrap (`EventKitCalendarReader`).
- Protocols expose the minimum surface a consumer needs — avoid "fat" protocols that leak implementation detail.

### Agent Contract

Every AI agent conforms to the shared `Agent` protocol described in [AI Agent Architecture](ARCHITECTURE.md#ai-agent-architecture):

```swift
protocol Agent {
    associatedtype SignalType: Signal
    func observe() async throws -> [SignalType]
    func predict(context: DayContext) async throws -> [Prediction]
}
```

- `observe()` must be side-effect-free — it reads, it never writes.
- `predict(context:)` must be deterministic given the same context and signals, so agent behavior is testable without mocking randomness.
- Agents never call each other directly; cross-agent context flows through the Ghost Brain (`Core`) only.

### Errors

Public API surfaces throw typed errors (see [Error Handling](ENGINEERING_GUIDE.md#error-handling)), not `Bool` return values or optional-as-failure. A `nil` return means "no result," never "something went wrong."

### Async by Default

All I/O-bound APIs — network, disk, system frameworks — are `async`, using Swift Concurrency. Completion-handler APIs are only acceptable at the boundary of a third-party SDK that hasn't adopted `async`/`await`, and are wrapped immediately with `withCheckedThrowingContinuation` rather than propagated upward.

## External API (Future)

LifePilot does not yet expose a public HTTP API. Once the companion web dashboard and third-party integration surface (Phase 10) begin, the following conventions apply:

### Design

- **REST** over JSON as the default; GraphQL is not currently planned, to keep the surface simple for third-party integrators.
- Resource-oriented URLs (`/v1/briefings/{id}`, not `/v1/getBriefing`).
- Versioned via URL path (`/v1/...`), with breaking changes requiring a new version, never an in-place change to `v1`.

### Authentication

- Bearer tokens issued via Supabase Auth (see [Technology Stack](../README.md#technology-stack)).
- Third-party integrations authenticate via scoped, revocable API keys — never a user's primary credentials.

### Response Shape

```json
{
  "data": { "...": "..." },
  "meta": { "requestId": "...", "generatedAt": "2026-07-09T08:00:00Z" }
}
```

Errors follow a consistent envelope:

```json
{
  "error": {
    "code": "briefing_not_ready",
    "message": "The morning briefing has not finished generating.",
    "retryable": true
  }
}
```

### Stability

Endpoints are considered unstable (subject to change without a major version bump) until explicitly documented as stable in a versioned API reference. This document will be expanded with a full endpoint reference once Phase 10 work begins — it intentionally stays high-level until there's a real surface to document precisely.
