---
description: Routing for Cursor Approval Agents on LifePilot PRs
globs:
alwaysApply: true
---

# Approval routing

Default policy file: `/APPROVAL_POLICY.md`

When reviewing:

1. Run through Bugbot focus in `.cursor/BUGBOT.md`
2. Apply `/APPROVAL_POLICY.md` approve / request-changes rules
3. Prefer commenting with concrete blockers before requesting changes
4. Never approve only because CI is green if scope or security policy is violated
