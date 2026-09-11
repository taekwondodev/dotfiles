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

## Runtime boundary: observe vs control (Hermes)

A companion observes Hermes runtime data; it cannot drive live sessions. This is not just policy — it is enforced by Hermes internals (verified against the local Hermes source):

- **Enumerate active sessions: yes.** Read `$HERMES_HOME/runtime/active_sessions.json` (or `hermes_cli.active_sessions.active_session_registry_snapshot()`). Entries carry `session_id`, `surface` (`cli`/`desktop`/`gateway`), `pid`, liveness — enough to know WHAT is running. The lease does NOT expose model/provider, so "sessions running on model X" is not derivable.
- **Inject a message / steer / pause into a live session: no.** `/steer` drains an in-memory same-process queue (`agent._drain_pending_steer()` in `agent_runtime_helpers.py`); there is no cross-process channel. The active-session registry enforces per-session single-writer exclusivity (`SESSION_NOT_OWNED` refusal); an external writer to a session with a live owner is rejected by design. Injecting a synthetic user message mid-loop is an explicit Hermes anti-invariant.
- **`hermes send`** delivers only to configured gateway platforms (Telegram/Discord/Slack/…), never to an agent session.
- **`hermes pause`** is a global emergency stop: it halts NEW cron/kanban/gateway turns only, never in-flight work, never a live desktop/CLI session, and produces no handoff.

So any "auto-pause the running agents" idea driven from a companion is not implementable; the natural home is Hermes-side (an agent/cron that observes the quota and steers its own `delegate_task` children). See `references/hermes-runtime-control-surface.md` for the detailed verification matrix.

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

## Running-artifact verification before assuming a UI regression

When the user reports behavior that contradicts the current source (e.g. "the scroll bar is visible again" while `ScrollView` still has `.scrollIndicators(.hidden)`), do NOT assume a code regression and jump into the source. First prove which binary is actually running:

- `ps aux | grep -i <app>` → exec path and start time. Confirm the running process uses `~/Applications/<App>.app/Contents/MacOS/<App>` (or the real install location), not a stale `.build/` copy.
- Compare timestamps: `.build/<config>/<binary>`, installed `.app/Contents/MacOS/<binary>`, and `git log -1 --format=%cI` of HEAD. A build date equal to the last commit date means the installed artifact carries the current source.
- SingleInstanceGuard gives a classic false "regression": if an old process is still alive, launching the updated `.app` just `exit(EXIT_SUCCESS)`es, so the user keeps seeing the OLD binary while the source on disk is already fixed. Check for a live process that predates the latest build.
- On this machine macOS overlay scroll scrollers render persistently (they do not auto-hide for the mouse); ADR-0006 records that `.scrollIndicators(.hidden)` is the fix and that `contentMargins(_:for: .scrollContent)` never separates the bar from content. If a scroll bar reappears with `.scrollIndicators(.hidden)` present in the running binary, distinguish idle-vs-expanded-state overflow (expanded DisclosureGroup pushes content past `maxHeight` 700) rather than re-litigating the modifier chain.

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
