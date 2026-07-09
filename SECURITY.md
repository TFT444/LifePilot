# Security Policy

## Our Philosophy

LifePilot is built privacy-first. It reasons over sensitive personal data — calendars, email, location, and financial signals — and that responsibility shapes every architectural decision:

- **On-device by default.** Processing happens on-device wherever feasible.
- **Encrypted sync.** Cross-device data is end-to-end encrypted via CloudKit.
- **No silent execution.** High-risk actions (sending a message, booking travel, moving money) always require explicit, per-action user approval — see the [Core Philosophy](README.md#core-philosophy).
- **Least privilege.** Each integration is granted the minimum access its agent needs to function.
- **Auditable actions.** Every executed action is logged with the reasoning that produced it.

Security is not a feature we bolt on — it's a constraint every agent and integration is designed under. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how this is enforced structurally.

## Supported Versions

LifePilot is pre-1.0 and under active development. Until the first stable release, only the latest `main` release receives security fixes.

| Version | Supported |
|---|---|
| `0.x` (latest release) | ✅ |
| `0.x` (older releases) | ❌ |
| `main` (unreleased) | ✅ best-effort |

Once `v1.0.0` ships, this table will be updated to reflect a formal support window (typically the latest major version plus one prior minor).

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Report vulnerabilities privately using one of the following channels:

1. **Preferred:** [GitHub Security Advisories](https://github.com/TFT444/LifePilot/security/advisories/new) — private by default, and lets us collaborate on a fix before disclosure.
2. **Email:** tamimtarafder12@gmail.com — include as much detail as possible (see below).

### What to Include

- A clear description of the vulnerability and its potential impact.
- Steps to reproduce, or a proof-of-concept if available.
- The affected version, commit, or branch.
- Any suggested mitigation, if you have one.

### What to Expect

| Stage | Target Timeline |
|---|---|
| Acknowledgment of report | Within 3 business days |
| Initial assessment and severity triage | Within 7 business days |
| Fix developed and validated | Timeline communicated after triage, based on severity |
| Public disclosure | Coordinated with the reporter, after a fix is released |

We follow **coordinated disclosure**: we ask that you give us a reasonable window to investigate and ship a fix before any public disclosure, and we commit to keeping you informed throughout.

### Scope

In scope:

- The LifePilot iOS/macOS application and its first-party Swift packages.
- The Ghost Brain reasoning engine and AI agent implementations in this repository.
- Official GitHub Actions workflows in `.github/workflows/`.

Out of scope:

- Third-party services LifePilot integrates with (report those to the vendor directly — Supabase, OpenAI, Apple, etc.).
- Social engineering, physical attacks, or denial-of-service against infrastructure.
- Findings that require a jailbroken/rooted device or a compromised OS.

Thank you for helping keep LifePilot and its users safe.
