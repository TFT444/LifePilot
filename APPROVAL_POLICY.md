# LifePilot Pull Request Approval Policy

This policy is for Cursor **Approval Agents** / Automations that may approve PRs as the `cursor` GitHub identity so a solo maintainer is not blocked by GitHub's "require approving review" rule.

## When the bot MAY approve

Approve only when **all** of the following are true:

1. GitHub Actions required checks are green (or still pending solely for unrelated flaky networking after a green previous SHA with no code change) — prefer green Build, Lint, Test, CI Status.
2. Cursor Bugbot has completed and does **not** report unresolved blocking findings for this head SHA.
3. The diff does **not** introduce finance/banking/commerce, HealthKit/medical MVP scope, Mail auto-send, or client-side secrets.
4. No new external write path bypasses `ActionProposal` → explicit approval → executor.
5. The PR description is truthful about what was verified (no fabricated simulator results).

## When the bot MUST NOT approve

Request changes or leave a comment without approval if:

- CI is failing for this head commit
- Bugbot reports unresolved blocking issues
- Secrets, credentials, or `.env` material appears in the diff
- Scope regression (finance/shopping/health MVP / auto-email send) appears
- Large architectural rewrites with no tests
- The PR targets `main` with incomplete release notes for a breaking change

## Solo-maintainer note

GitHub disallows self-approval by `@TFT444`. Approvals from the Cursor GitHub App / `cursor` bot are a different identity and are intended to satisfy required reviews when Bugbot + CI agree the change is safe. The human maintainer remains responsible for product judgment and for using `gh pr merge --admin` only as a documented break-glass option.

## References

- `.cursor/BUGBOT.md`
- `docs/SOLO_MAINTAINER_REVIEW.md`
- `docs/IMPLEMENTATION_STATUS.md`
- Issue #7
