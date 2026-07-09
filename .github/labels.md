# Label Taxonomy

LifePilot uses a structured label system so issues and pull requests are triageable at a glance. Labels are grouped by prefix; each issue should carry at most one label from each group.

## `type:` — what kind of work this is

| Label | Color | Description |
|---|---|---|
| `type: bug` | `#d73a4a` | A defect in existing behavior |
| `type: feature` | `#0e8a16` | A new capability |
| `type: task` | `#1d76db` | Engineering work with no direct user impact |
| `type: documentation` | `#0075ca` | Docs only |
| `type: performance` | `#fbca04` | Speed, memory, or resource usage |
| `type: security` | `#b60205` | Security or privacy concern |
| `type: question` | `#d876e3` | A question, not actionable work |
| `type: dependencies` | `#0366d6` | Dependency version bumps |

## `status:` — where it is in the pipeline

| Label | Color | Description |
|---|---|---|
| `status: triage` | `#ededed` | Newly opened, not yet reviewed |
| `status: accepted` | `#c2e0c6` | Confirmed and prioritized |
| `status: in-progress` | `#fef2c0` | Actively being worked |
| `status: blocked` | `#e99695` | Waiting on an external dependency or decision |
| `status: needs-review` | `#bfd4f2` | Pull request awaiting review |
| `status: wontfix` | `#ffffff` | Closed without action, with rationale |

## `priority:` — how urgent

| Label | Color | Description |
|---|---|---|
| `priority: critical` | `#b60205` | Drop everything — data loss, security, production down |
| `priority: high` | `#d93f0b` | Should land in the current milestone |
| `priority: medium` | `#fbca04` | Normal priority |
| `priority: low` | `#c5def5` | Nice to have, no urgency |

## `area:` — which part of the system

| Label | Color | Description |
|---|---|---|
| `area: core` | `#5319e7` | Ghost Brain reasoning engine |
| `area: agents` | `#5319e7` | AI agent implementations |
| `area: design-system` | `#5319e7` | Shared UI components and tokens |
| `area: ci` | `#5319e7` | Build, lint, test, release pipelines |
| `area: web` | `#5319e7` | Companion web dashboard |

## `good first issue` and `help wanted`

| Label | Color | Description |
|---|---|---|
| `good first issue` | `#7057ff` | Scoped and well-suited for a first contribution |
| `help wanted` | `#008672` | Maintainers are actively looking for help here |

---

New labels should be proposed via pull request against this file before being created in the repository, so the taxonomy stays documented and intentional.
