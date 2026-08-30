---
name: hermes-macos-usage-companion
description: "Use for macOS companions monitoring Hermes Agent usage."
---

# Hermes macOS Usage Companion

Use this class-level skill for native macOS menu bar companions that observe Hermes Agent profiles, provider quotas, local accounting, reset windows, and update compatibility.

## Producer-first investigation

1. Resolve the effective Hermes root and active profile separately.
   - Root/account-global data commonly lives under `~/.hermes`.
   - Profile-local data commonly lives under `~/.hermes/profiles/<profile>`.
   - A Finder-launched `.app` usually has no inherited `HERMES_HOME`; `swift run` may inherit a profile environment.
2. Probe the current Hermes producer before changing SwiftUI. The Hermes CLI exposes **no `usage` subcommand** (verified against v0.20.x: `hermes usage` fails `invalid choice`). Use the bundled bridge, which calls the upstream Python API `agent.account_usage.fetch_account_usage` directly:
   ```bash
   "$HOME/.hermes/hermes-agent/venv/bin/python" \
     "$PROJECT/scripts/hermes_usage_bridge.py" --json --hermes-root "$HOME/.hermes/hermes-agent"
   ```
   or probe the API in-process. Note: an app bundle launcher resolves the bridge from `Contents/Resources`; from the repo run the `.py` with the Hermes venv python instead.
   Print only provider names, statuses, window kinds, percentages, reset timestamps, and safe schema metadata. Never print API keys, headers, cookies, prompts, transcripts, or raw database rows.
3. Confirm the command exists in the current producer branch. An orphan or stale local commit is not evidence that the installed Hermes executable still exposes the command.
4. Inspect the live provider schema before writing a decoder. OpenCode Go has returned:
   ```json
   {"usage":{"rolling":{"percent":4,"resetsAt":"..."},"weekly":{"percent":41,"resetsAt":"..."},"monthly":{"percent":25,"resetsAt":"..."}}}
   ```
   Its endpoint requires both `Authorization: Bearer <key>` and `x-api-key: <key>`; never expose either value.

## Bridge design

- Keep provider quota, local token/request/cost accounting, identity, freshness, and unavailable reasons as separate concepts.
- Map technical providers to commercial subscriptions at the adapter boundary.
- Do not derive official quota percentages from historical token usage.
- Preserve healthy provider sources when one source is malformed, unsupported, unauthorized, or unavailable.
- Represent command missing, authentication failure, endpoint failure, malformed payload, and unsupported version distinctly when the producer exposes enough evidence.
- Read `state.db` read-only.
- Pass subprocess arguments as arrays, not shell-interpolated strings.
- Drain or discard stderr safely, enforce bounded subprocess timeouts, and terminate hung children.
- Keep mutable reset baselines in an actor/service; never put reset rules in a refresh button handler.

## Reset notification semantics

A manual refresh keeps its normal data-acquisition behavior and is not itself a notification trigger. A manual refresh may notify only when it observes this exact live transition:

```text
previous.usedPercent > 0
AND current.usedPercent == 0
AND current.resetAt > previous.resetAt
```

Do not notify for:

- `0% -> 0%` repeated observations;
- a reset timestamp that is missing or not advanced;
- a simple usage variation without reset evidence;
- a reset that occurred while the app was stopped (first post-launch live data is a silent baseline).

Aggregate simultaneous verified window resets into one notification containing provider and window labels.

## SwiftUI/macOS runtime

- Keep the automatic refresh lifecycle independent from popover visibility and cancellable.
- A `MenuBarExtra(.window)` popover needs explicit width plus stable min/ideal/max height; max-only sizing can collapse to a tiny blank panel.
- Use a real `@Binding` for `DisclosureGroup` expansion; its setter must assign the supplied boolean, not blindly toggle.
- Keep identity icons stable and separate from quota/status colors.
- For provider bitmap assets, verify source files and the actual release resource bundle. If `Image(name, bundle:)` renders a blank placeholder, load explicitly from the installed bundle with `NSImage(contentsOf:)` and `Image(nsImage:)`.
- `swift run` is not an app bundle. Guard `UserNotifications` and app identity calls when `Bundle.main.bundleURL.pathExtension != "app"`.
- For SwiftPM executable resources in a packaged `.app`, place the resource bundle under `Contents/Resources` and resolve it with `Bundle.main.url(forResource:withExtension:)`; do not rely on the generated `.build` absolute fallback.
- Use an explicit app bundle with Info.plist, `LSUIElement`, stable bundle identifier, ad-hoc signing for personal use, and a real `.app` launch smoke test.

## Hermes update resilience

- Upstream Hermes `main` remains the source of truth; do not push local compatibility patches to the upstream repository.
- Keep local compatibility patches and reports outside the upstream checkout under `~/.hermes/update-safe/`.
- A safe update flow must preserve local changes, update `main`, skip the patch if upstream now owns the contract, apply/check the patch otherwise, validate usage JSON, and restore local changes in a `finally` path.
- Restore conflicts must be reported as partial degradation, not success.
- Reports must not contain credentials or raw command output.
- If compatibility fails, keep Hermes updated and disable only the incompatible source in the app; do not invent quota values or roll Hermes back.

## Verification checklist

- Run the live producer probe.
- Run fixture tests for valid, malformed, unsupported, unavailable, and schema-drift payloads.
- Run `swift test` and `swift build -c release -Xswiftc -strict-concurrency=complete`.
- Validate the installed `.app`, Info.plist, resources, signature, and process liveness separately from Swift tests.
- Hash `state.db` and credential files before/after compatibility verification; a change must fail the verifier.
- Store a timestamped non-sensitive report under `~/.hermes/update-safe/`.
- Preserve unrelated pre-existing changes in the Hermes checkout; never stage or commit them accidentally.
