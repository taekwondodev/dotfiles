---
name: swiftpm-app-build-tooling
description: Add a Makefile for a script-built SwiftPM macOS app.
---

# SwiftPM macOS app build tooling via a thin Makefile

For a macOS app built with SwiftPM where the delivered `.app` bundle is assembled,
signed, and installed by shell scripts under `./scripts`. Use this when the user asks
for a Makefile, build automation, or a narrower command surface over existing scripts.

## The pattern: pure-delegating thin wrapper

The correct division of responsibility:

- **`./scripts/*.sh` / `.py` remain the single source of truth** for app assembly,
  signing, install, and verification. Never duplicate their logic in the Makefile.
- **The Makefile is a name-shortening wrapper only.** Each target executes an existing
  script or a standard SwiftPM command. Zero inline build logic.
- **Never introduce a parallel path**: no dedicated targets that redo what a script
  already does (e.g. do NOT add a `refresh-bridge` target when the bridge is already
  copied by `build-app.sh`). A parallel path means two truths diverge.
- Document the convention: AGENTS.md should name the Makefile as the entry point for
  commands, and NOT list the individual scripts as commands (scripts stay source of
  truth but are not the user-facing command surface).

## Pitfalls (learned live)

- **Bare `make` defaults to the FIRST target.** If `build` is listed first, `make`
  with no arguments silently rebuilds/relaunches the app — an unwanted side effect.
  Fix: set `.DEFAULT_GOAL := help` and keep `help` as the safe default.
- **SwiftPM commands need the package root as cwd; scripts often don't.** Shell
  scripts that resolve the project root via `$BASH_SOURCE` work from any directory, but
  `swift build` / `swift test` / `swift package clean` must run from the package root.
  Anchor the Makefile with
  `ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))` and `cd "$(ROOT)" && swift ...`.
- **`clean` is dangerous by naming.** Users assume it cleans the installed app. Bind it
  strictly to `.build`: `cd "$(ROOT)" && swift package clean`. See references for how
  to verify it never touches `~/Applications`.
- **An install script that prompts on `/dev/tty` aborts in a non-interactive shell.**
  If the build script asks the user to confirm when the app is already running (the
  `build-app.sh` pattern does: "<App> is currently running. Close it before installing"),
  it typically `read`s the answer from `/dev/tty` — which does not exist in an agent or
  cron shell, so the install dies with "Device not configured" and `make build` exits
  non-zero. Fix: quit the running app FIRST, then re-run the build. Use
  `osascript -e 'tell application "<App>" to quit'` (wait for `pgrep -x <App>` to clear)
  or `pkill -TERM -x <App>` + a short wait loop, confirm the process is gone, then
  `make build`. The script only prompts while the app is running; with it quiesced it
  proceeds straight to install + relaunch. This shapes the whole install/relaunch loop
  in a headless context, not just `build`.

## Verification before trusting a destructive target

Before shipping a `clean` target, verify empirically it does NOT touch the installed
bundle. See `references/swift-package-clean.md` for the exact before/after checks
(mtime on the installed executable must be identical, signature must still verify).

## Target shape that worked for a menu-bar quota app

A good minimal set, all pure-delegating:
- `build` → `./scripts/build-app.sh` (primary)
- `verify` → `./scripts/verify-installed-app.sh`
- `check` → `./scripts/verify-hermes-compatibility.py`
- `test` → `swift test` (real gap to fill: no script covers it)
- `clean` → `swift package clean` (`.build` only)
- `help` → list targets

## Verification of the wrapper itself

Run the full target inventory in dry-run: `make -n <target>` for every target, and
also `make -n` (bare) to confirm the default goal is `help`, not `build`. Then run at
least one non-destructive real target (e.g. `make check`) to prove execution.