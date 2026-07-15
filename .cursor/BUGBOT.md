# Bugbot — LifePilot review focus

Use this file when reviewing pull requests for `TFT444/lifepilot`.

## Product scope (hard rules)

Reject or flag as blocking if the PR introduces:

- Banking, balances, transactions, spending, bills, payments, or investment features
- Shopping / checkout / purchase automation
- HealthKit or medical/health intelligence as a shipping feature
- Apple Mail content ingestion or automatic message sending
- API keys, tokens, or secrets embedded in client code, tests, assets, or logs
- Any code path that executes an external write without ActionProposal → Approval → Executor

## Architecture checklist

- Features depend on Core protocols, not Mocks/Services concretions (except AppShell composition root)
- GhostBrain / planning only depends on Core
- Deterministic planning remains primary; optional AI must be behind a protocol and disabled by default
- Recommendations must carry evidence, freshness, and reason when added

## Security / privacy

- Least privilege; no silent preference promotion
- Sensitive content must not appear in notification previews by default
- Audit events must not store secrets or unnecessary private payloads
- Export/delete of LifePilot-owned data must remain possible when persistence changes

## Test expectations

- New domain logic ships with unit tests
- Approval-bypass, fingerprint mismatch, and denied action types stay covered
- Do not invent claims that Xcode/simulator checks passed if they did not run

## Review style

- Prefer actionable comments with a concrete fix suggestion
- Separate blocking issues from non-blocking nits
- If CI is red, say so and do not suggest merge
