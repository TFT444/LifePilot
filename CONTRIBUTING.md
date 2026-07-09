# Contributing to LifePilot

Thank you for considering a contribution to LifePilot. This document explains how the project is developed, reviewed, and released, so your first contribution goes smoothly.

## Table of Contents

- [Development Workflow](#development-workflow)
- [Branch Naming](#branch-naming)
- [Commit Messages](#commit-messages)
- [Coding Standards](#coding-standards)
- [Pull Request Process](#pull-request-process)
- [Issue Process](#issue-process)
- [Review Process](#review-process)

## Development Workflow

LifePilot follows [Git Flow](docs/ARCHITECTURE.md). In short:

1. `main` is always production-ready and protected. No one commits to it directly.
2. `develop` is the active integration branch. All feature work starts here.
3. You branch from `develop`, do your work, and open a Pull Request back into `develop`.
4. Periodically, `develop` is merged into `main` as part of a tagged release.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and the [README's Branch Strategy](README.md#branch-strategy) for the full picture, including diagrams.

## Branch Naming

| Pattern | Use case | Example |
|---|---|---|
| `feature/<short-description>` | New functionality | `feature/morning-briefing-card` |
| `fix/<short-description>` | Bug fixes on `develop` | `fix/timeline-scroll-jitter` |
| `hotfix/<short-description>` | Urgent fixes cut from `main` | `hotfix/crash-on-launch` |
| `release/<version>` | Release stabilization | `release/1.2.0` |
| `docs/<short-description>` | Documentation only | `docs/update-architecture` |
| `chore/<short-description>` | Tooling, CI, dependencies | `chore/bump-swiftlint` |

Use lowercase, hyphen-separated descriptions. Keep them short but specific enough to identify the work without opening the branch.

## Commit Messages

LifePilot uses [Conventional Commits](https://www.conventionalcommits.org/). This keeps history readable and powers automated changelog generation.

```
<type>(<scope>): <short summary>

[optional body]

[optional footer]
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`, `build`

**Examples:**

```
feat(home): add morning briefing dashboard
fix(timeline): resolve scrolling issue
docs(readme): update installation guide
refactor(memory): improve recommendation engine
style(ui): update spacing tokens
test(calendar): add integration tests
chore(deps): bump swift-collections to 1.1.0
```

A breaking change is indicated with `!` after the type/scope and a `BREAKING CHANGE:` footer:

```
feat(agents)!: change CalendarAgent output schema

BREAKING CHANGE: `CalendarAgent.predict()` now returns `[CalendarSignal]`
instead of `[CalendarEvent]`. Callers must migrate to the new type.
```

## Coding Standards

Full detail lives in [docs/STYLE_GUIDE.md](docs/STYLE_GUIDE.md) and [docs/ENGINEERING_GUIDE.md](docs/ENGINEERING_GUIDE.md). At a glance:

- Swift code follows the project's [Style Guide](docs/STYLE_GUIDE.md#swift-style-guide), enforced by SwiftLint and SwiftFormat in CI.
- Architecture follows MVVM with dependency injection — see [ARCHITECTURE.md](docs/ARCHITECTURE.md).
- New logic requires tests. See [Testing Strategy](docs/ENGINEERING_GUIDE.md#testing-strategy).
- Public types and non-obvious logic should be documented with `///` doc comments.

## Pull Request Process

1. Fork the repository (external contributors) or branch directly (core team).
2. Create a branch from `develop` following the [naming convention](#branch-naming) above.
3. Make focused, atomic commits using [Conventional Commits](#commit-messages).
4. Ensure the project builds, lints, and all tests pass locally.
5. Open a Pull Request against `develop` using the [PR template](.github/PULL_REQUEST_TEMPLATE.md) — fill in every section, including screenshots for UI changes.
6. Link related issues (`Closes #123`).
7. Ensure CI is green before requesting review.
8. Address review feedback with additional commits; avoid force-pushing mid-review unless asked to.
9. A maintainer merges once approved and CI passes. Squash-merge is the default merge strategy to keep `develop` history clean.

## Issue Process

- Search existing issues before opening a new one.
- Use the appropriate [issue template](.github/ISSUE_TEMPLATE/) — bug, feature, task, documentation, performance, security, or question.
- Provide enough detail for a maintainer to act without follow-up questions: reproduction steps, environment, expected vs. actual behavior.
- Security vulnerabilities must go through the private disclosure process in [SECURITY.md](SECURITY.md), not a public issue.

## Review Process

- Every Pull Request requires at least one approving review before merge (see [CODEOWNERS](.github/CODEOWNERS)).
- CI (build, lint, test) must pass before merge — no exceptions, no `--no-verify`.
- Reviewers focus on correctness, architecture fit, test coverage, and adherence to the style guide.
- Direct pushes to `main` and `develop` are disabled by branch protection; everything goes through review.
- Force-pushes to shared branches (`main`, `develop`) are disabled.

---

Questions not covered here? Open a [Question issue](.github/ISSUE_TEMPLATE/question.yml) or start a Discussion.
