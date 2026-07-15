# Solo maintainer PR review (Cursor bot)

LifePilot is currently a **one-person** repository (`@TFT444`). Branch protection requires at least one approving review, and GitHub forbids self-approval. That is tracked in issue [#7](https://github.com/TFT444/lifepilot/issues/7).

This document is the supported way to get a **second identity** (Cursor) to review and, when safe, approve PRs.

## What to turn on (you must do this in Cursor — agents cannot)

### 1) Connect GitHub to Cursor

1. Open [cursor.com/dashboard/integrations](https://cursor.com/dashboard/integrations)
2. Connect **GitHub**
3. Grant access to `TFT444/lifepilot` (All repos or selected)

### 2) Enable Bugbot (automated review comments + check)

1. Open [cursor.com/dashboard/bugbot](https://cursor.com/dashboard/bugbot)
2. Enable Bugbot for `lifepilot`
3. Confirm billing / plan allows Bugbot runs
4. On a PR, Bugbot should appear as the **`Cursor Bugbot`** check  
   Manual trigger comments: `cursor review` or `bugbot run`

Bugbot uses `.cursor/BUGBOT.md` in this repo for LifePilot-specific review focus.

**Important:** Bugbot comments and checks are **not** the same as a GitHub “Approve” review. Bugbot alone will not clear “Require approving reviews.”

### 3) Enable Approval Agents (this is what can approve)

1. Open Cursor **Approval Agents** in the dashboard  
   Docs: [Approval Agents](https://cursor.com/docs/bugbot.md) and [Approval Agents](https://cursor.com/docs/approval-agents.md)
2. Create a **Pull Request Approver** agent
3. Triggers: **PR opened**, **PR pushed/updated**
4. Scope: `TFT444/lifepilot`
5. Enable:
   - **Use Bugbot Review Context** (wait for Bugbot; do not approve on open findings)
   - Primary action: **Approve PR**
6. Point it at repo policy:
   - `APPROVAL_POLICY.md`
   - `.cursor/approval-policies/ROUTING.md`

Approvals from this path show up as the **`cursor`** GitHub identity — a different author than `@TFT444`, which is what solo branch protection needs.

### Alternative: Automations

At [cursor.com/automations](https://cursor.com/automations):

1. Trigger: PR opened / PR pushed
2. Tool: **Comment on pull request** with **approvals** allowed
3. Prompt: follow `APPROVAL_POLICY.md`; approve only when CI + Bugbot are clean and scope rules pass
4. Docs: [Cloud Agent Automations](https://cursor.com/docs/cloud-agent/automations.md)

## Optional GitHub branch protection tweaks

Repo → **Settings** → **Branches** / **Rulesets**:

| Option | Effect |
|---|---|
| Keep “1 approving review” + Approval Agent | Best safety: CI + Bugbot + Cursor approve |
| Also require status check `Cursor Bugbot` | Blocks merge until Bugbot ran |
| Temporarily set required reviewers to 0 | Unblocks solo merges but removes peer review — not preferred |

Do **not** rely on `gh pr merge --admin` as the normal path. Keep it as break-glass only and note it in the PR body when used.

## Verify on a real PR

1. Open or push to [PR #39](https://github.com/TFT444/lifepilot/pull/39) (or any draft PR)
2. Confirm **Cursor Bugbot** check runs
3. Confirm Approval Agent posts an **Approve** (or a comments-only review with blockers)
4. Confirm the PR “Review required” gate clears for your account
5. Merge via normal green button (no `--admin`)

## Files added for this workflow

| File | Purpose |
|---|---|
| `.cursor/BUGBOT.md` | LifePilot-specific Bugbot review focus |
| `APPROVAL_POLICY.md` | When Cursor may / must not approve |
| `.cursor/approval-policies/ROUTING.md` | Points Approval Agents at the policy |
| `.github/workflows/request-cursor-review.yml` | Reminds humans how to trigger Bugbot on each PR |

## If Approval Agents are unavailable on your plan

Temporary options that still improve safety:

1. Require CI checks only (set approving review count to 0) **and** always run Bugbot
2. Create a second GitHub user you control solely as a reviewer (weak; not recommended long-term)
3. Use `--admin` merges with a written “why no peer review” note in the PR (documented in issue #7)
