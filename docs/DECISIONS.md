# Architecture Decision Records

This document records significant, hard-to-reverse engineering decisions — the "why" behind choices that aren't obvious from reading the code. Each entry is short: context, decision, consequences. New entries are appended; existing entries are never edited to look retroactively obvious — if a decision is later reversed, add a new entry that supersedes it rather than rewriting history.

Format adapted from [Michael Nygard's ADR template](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions).

---

## ADR-001: Native SwiftUI over cross-platform framework

**Status:** Accepted

**Context:** LifePilot's core value depends on deep, trustworthy integration with system frameworks — Calendar, Mail, Location, Weather, CloudKit — and on feeling like a native, high-craft part of iOS/macOS, not a web view.

**Decision:** Build with SwiftUI natively rather than React Native, Flutter, or a similar cross-platform framework.

**Consequences:** Faster, more reliable access to system frameworks and platform idioms. Slower to port to Android; a future Android client would be a separate, native effort rather than shared code. Accepted given the initial target platform and audience — see [Technology Stack](../README.md#technology-stack).

---

## ADR-002: Ghost Brain as a single fusion point, not per-agent orchestration

**Status:** Accepted

**Context:** Agents (Calendar, Email, Travel, ...) each reason within their own domain, but many of the most valuable predictions are cross-domain (a flight delay affecting a meeting). Agents could either talk to each other directly, or report to a central reasoning core.

**Decision:** All cross-agent reasoning happens in the Ghost Brain (`Core`). Agents never call each other directly — see [AI Agent Architecture](ARCHITECTURE.md#ai-agent-architecture).

**Consequences:** Cross-domain reasoning is centralized, testable, and inspectable in one place, rather than scattered across N² agent-to-agent integrations. Adding a new agent requires no changes to existing agents. The tradeoff is that the Ghost Brain must be the one place that scales in complexity as agents are added — mitigated by the shared `Agent` protocol keeping its interface with each agent uniform.

---

## ADR-003: No autonomous execution without explicit approval

**Status:** Accepted

**Context:** LifePilot reasons over sensitive, consequential data (calendars, email, finances) and could technically act on the user's behalf (send an email, book travel, move money).

**Decision:** No high-risk action executes without explicit, per-action user approval, enforced architecturally (see [Dependency Rules](ARCHITECTURE.md#dependency-rules), point 4) rather than as a UI convention that could be bypassed.

**Consequences:** Slower to demonstrate "magic" automation in early demos. Substantially safer, more trustworthy, and more defensible as the product scales — see [SECURITY.md](../SECURITY.md). Automation is earned incrementally — [Phase 5](../MASTER_ROADMAP.md#phase-5--ghost-brain) introduces gated, explained predictions; user-defined automation rules don't arrive until [Phase 10](../MASTER_ROADMAP.md#phase-10--lifepilot-platform) — rather than assumed from day one. See [Product Principles](PRODUCT_VISION.md#product-principles).

---

## ADR-004: Git Flow over trunk-based development

**Status:** Accepted

**Context:** The team is small today but the repository needs to support a growing set of external contributors without destabilizing `main`.

**Decision:** Use Git Flow (`main`, `develop`, `feature/*`, `hotfix/*`, `release/*`) rather than trunk-based development with feature flags — see [Branch Strategy](../README.md#branch-strategy).

**Consequences:** `main` is always releasable, and external contributions land in `develop` without risk to production stability. The tradeoff is an extra integration branch to keep in sync — accepted given the project doesn't yet have the deployment infrastructure (feature flags, staged rollouts) that makes trunk-based development safe at this stage. This will be revisited if/when continuous deployment infrastructure is built.

---

## ADR-005: Protocol-first module boundaries

**Status:** Accepted

**Context:** `Core` and `Agents` need to remain testable in isolation and portable to future surfaces (e.g. a web dashboard reusing the same reasoning engine).

**Decision:** Every cross-module dependency is expressed as a protocol owned by the consuming layer, per [API Guidelines](API_GUIDELINES.md#internal-module-apis), rather than modules depending on each other's concrete types directly.

**Consequences:** Slightly more boilerplate (a protocol plus a concrete conformance) than direct dependencies. In exchange, `Core` and `Agents` can be unit-tested with fakes instead of real system frameworks or network calls, and integrations (Supabase, OpenAI, CloudKit) can be swapped without touching domain logic.

---

## Template for New Entries

```markdown
## ADR-XXX: <short title>

**Status:** Proposed | Accepted | Superseded by ADR-YYY

**Context:** What forces are at play — technical, product, or organizational — that make this decision necessary?

**Decision:** What did we decide?

**Consequences:** What becomes easier or harder as a result? What did we give up?
```
