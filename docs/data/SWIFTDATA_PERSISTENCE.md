# Offline-first persistence model (SwiftData)

Closes design acceptance for issue [#34](https://github.com/TFT444/lifepilot/issues/34).

## Goals

- LifePilot-owned state works **fully offline** with no account.
- External systems (EventKit Calendar/Reminders) remain sources of truth when connected; LifePilot stores **links and metadata**, not forks of their primary keys as our only identity.
- CloudKit sync is optional and additive later — local store must never require it.

## Schema entities (MVP)

| Entity | Ownership | Notes |
|---|---|---|
| `TaskItem` / `TaskList` | LifePilot | Local UUID PK; optional `externalIdentifier` for Reminders link |
| `CalendarEvent` | LifePilot local or mirrored | Local UUID PK; `externalIdentifier` for EventKit; never use EventKit ID alone as PK |
| `UserPreferences` | LifePilot | Singleton document |
| `MemoryItem` | LifePilot | Explicit user memory only |
| `ActionProposal` / `ApprovalRecord` / `AuditEvent` | LifePilot | Approval trail; no secrets |
| `PlanningFinding` (derived) | Ephemeral or cached | May be recomputed; cache allowed with `freshness` |
| Sync metadata | LifePilot | Per-entity `SyncState`, `updatedAt` |

## Identifiers

- **Primary key:** always a LifePilot `UUID` generated via `IdentifierProviding`
- **External IDs:** stored in `externalIdentifier: String?` + `DataSource`
- Re-import / re-link must merge by external ID without rewriting LifePilot PK

## Schema versioning

- Current schema version: **1** (`PersistenceSchema.currentVersion`)
- Migrations live as explicit `PersistenceMigration` steps tested in unit tests
- v1 → v2 path is stubbed with an additive field migration example to prove the harness

## Sensitive fields and retention

| Field class | Protection | Retention |
|---|---|---|
| Task/event titles & notes | Device Data Protection (Complete until auth when persisted) | Until user deletes |
| Approval audit summaries | Prefer metadata over raw private content | Configurable; default keep 90 days intent (enforced in later CloudKit phase) |
| Memory items | User-controlled delete/export | Until user deletes |
| Tokens / API keys | **Never store in client DB** | N/A |

## Deletion

`PreferenceStore.deleteAllLifePilotData()` and future `PersistenceController.wipeAll()` must remove all LifePilot-owned records. External EventKit records are never deleted without an approved proposal.

## Implementation status

| Layer | Location | Status |
|---|---|---|
| Domain models | `Core/Models/*` | Done |
| Protocols | `Core/Protocols/StoreProtocols.swift` | Done |
| In-memory stores | `Services/Stores/InMemoryStores.swift` | Done (tests/previews) |
| Schema version + migration harness | `Core/Persistence/*` | Done |
| SwiftData `@Model` adapters | `Services/Persistence/*`, `Services/Stores/SwiftDataStores.swift` | Done for tasks/events/preferences/memory/approvals/audit |
| CloudKit sync | Optional later | Not started |

## Acceptance

- [x] Model supports MVP offline workflows via protocols + in-memory stores
- [x] SwiftData production stores wired through `AppDependencies.live`
- [x] Migration tests cover at least one schema upgrade harness step
- [x] External identifiers are not unstable primary keys
- [x] Sensitive fields and retention documented here
