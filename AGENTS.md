# AGENTS.md

## Cursor Cloud specific instructions

LifePilot is a native SwiftUI iOS/macOS app (Swift package, see `Package.swift`) with a
companion static web demo. The Cursor Cloud VM is **Linux**, so only part of the project
can build/run here. Read this before assuming something is broken.

### What can and cannot run on this Linux VM

- The SwiftUI presentation layer (`DesignSystem/`, `Features/`, `AppShell/`, `App/`) imports
  `SwiftUI`/`UIKit`/`AppKit` and can only be built, tested, and linted on **macOS + Xcode**.
  The GitHub CI jobs for build/test/SwiftLint/SwiftFormat run on `macos-15` (see
  `.github/workflows/{ci,test,lint}.yml`) and cannot be reproduced on Linux.
- The framework-agnostic modules (`Core/`, `GhostBrain/`, `Services/`, `Mocks/`) only use
  `Foundation`/`CoreGraphics` and DO build and test on Linux with the installed Swift toolchain.
- The interactive product demo (`index.html`, identical to `demo/index.html`) is a
  self-contained static web app with mock data — this is the runnable "application" on Linux.

### Swift toolchain (Linux)

A Swift 6.0.3 Linux toolchain is installed at `/opt/swift` and added to `PATH` via `~/.bashrc`
(`/opt/swift/usr/bin`). Verify with `swift --version`.

- `swift build` / `swift test` at the repo root **FAIL** on Linux because they compile the
  SwiftUI targets. Do not treat that failure as a regression.
- Build a single framework-agnostic module: `swift build --target LifePilotCore`
  (also `LifePilotGhostBrain`, `LifePilotServices`, `LifePilotMocks`).
- To RUN the framework-agnostic tests (Core/GhostBrain/Mocks), `swift test` won't work at the
  repo root, so use a throwaway "shadow" package that only references those targets. Create a
  temp dir, symlink `Core GhostBrain Services Mocks` and `Tests/{Core,GhostBrain,Mocks}` into it,
  add a `Package.swift` listing only those targets + test targets, then run `swift test` there.

### Running the web demo (the app you can actually run here)

From the repo root: `python3 -m http.server 8000`, then open `http://localhost:8000/index.html`.
No build step, no backend, no dependencies. The core loop to exercise is Smart Approvals: tap a
recommendation card, then tap **Approve** — the timeline updates in place.

### Markdown lint

`npx --yes markdownlint-cli2 "**/*.md"` (config: `.markdownlint-cli2.jsonc`). This mirrors the
only lint CI job that runs on Linux; the SwiftLint/SwiftFormat jobs are macOS-only.
