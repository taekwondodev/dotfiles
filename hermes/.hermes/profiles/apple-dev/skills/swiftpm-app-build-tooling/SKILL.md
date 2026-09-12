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

- **Freeze executable hashes only after final bundle signing.** `codesign` can mutate the Mach-O, so a digest captured from the raw SwiftPM executable will not bind the installed executable and can also make an emergency stop reject the launched app. For artifact-bound campaigns, retain the fully assembled signed bundle and install a byte-for-byte copy without re-signing; follow `references/transactional-app-install-rollback.md`.
- **Finish runner, protocol, candidate-ref, and independent review gates before freezing an immutable campaign.** Any later change to one of those bindings requires a fresh campaign directory; never patch retained evidence in place.
- **Parse designated requirements across current and legacy `codesign -d -r-` framing.** Inspect both stdout and stderr, accept `designated => …` and `# designated => …`, and require exactly one non-empty requirement; macOS versions differ in stream and comment-prefix framing even for a valid signature.
- **Distinguish rollback ownership from identity-isolated cleanup.** A transactional replacement may stop its corrupt candidate by the exact owned install path after validating the backup; a side-by-side campaign must instead revalidate the candidate identity before signaling and refuse on mismatch so it cannot affect the production app. Follow `references/transactional-app-install-rollback.md` for both threat models.

- **Enumerated file lists rot when files are removed.** A `check` command that lists Python files to `ast.parse`, JSON files to load, or Swift files to `swiftc -parse` by literal path fails on the first deleted file; so does a command-surface test that pins every Makefile target to its script. When removing scripts or targets, grep `scripts/` and `Tests/Tooling/` for the file and target names in the same change.
- **Sign with a stable identity, never ad-hoc, for apps that hold TCC grants (Accessibility, Input Monitoring, Screen Recording).** TCC identifies an app by bundle ID plus signing certificate; an ad-hoc signature is a fresh hash per build, so every `make build` silently voids the grant while the checkbox still looks on. Resolve the identity in the packaging script from the single `Apple Development` certificate (`security find-identity -v -p codesigning`); fail when zero or more than one match exists rather than falling back to `-`, and report the real signer in `verify` output (parse `Authority=` from `codesign --display --verbose=2`, which prints to stderr). Do not add a self-signed-certificate branch to the script unless the user asks for it: the free Personal Team certificate is enough and one code path keeps `verify` honest. Getting the certificate needs no paid membership: Xcode > Settings > Accounts > add Apple ID > Manage Certificates > `+` Apple Development. When Accounts shows "Failed to retrieve development teams" on an account whose paid membership lapsed, have the user accept any pending agreement on developer.apple.com, then remove and re-add the account; it usually yields the certificate on the second attempt. Only if that still fails, offer a self-signed code-signing certificate from Keychain Access (Certificate Assistant, Self Signed Root, Code Signing, Always Trust) and add it to the script explicitly.
- **Compile the app icon from an asset catalog at packaging time, not from a hand-made icns.** Keep `Resources/Media.xcassets/AppIcon.appiconset` as the only source (the user creates it in Xcode by opening the `.xcassets` folder directly; no Xcode project is needed) and run `xcrun actool <catalog> --compile <Contents/Resources> --platform macosx --minimum-deployment-target <floor> --app-icon AppIcon --output-partial-info-plist <tmp>` in the bundle assembler, asserting `AppIcon.icns` and `Assets.car` exist afterwards. Declare `CFBundleIconName = AppIcon` in the source plist and have `verify` check both the key and the icns. Fail when the icon set is missing rather than shipping without an icon.
- **Tightening the bundle contract must not be checked against the bundle being replaced.** When `verify_bundle` gains a new requirement (icon files, a plist key, a signer), every pre-replacement call that inspects the currently installed bundle (stop-before-install, backup reconciliation, rollback validation) now fails with a misleading "metadata does not match" because the old bundle predates the rule. Validate the previous bundle only structurally (directory, executable present) at those sites and apply the full contract only to the freshly staged bundle and to `verify`; trace the traceback to the exact caller before touching the contract itself.
- **Stop the process before deleting its bundle.** `rm -rf ~/Applications/<App>.app` while the app runs leaves an orphan process holding the executable with no bundle to quit from; `pgrep -fl <App>` first, `kill` the pid, then remove. Applies doubly to side-by-side candidate bundles the user may have left running from a manual test.

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