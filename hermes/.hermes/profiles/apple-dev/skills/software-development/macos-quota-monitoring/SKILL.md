---
name: macos-quota-monitoring
description: "Use for macOS quota-monitoring utilities."
version: 1.0.0
metadata:
  hermes:
    tags: [macOS, SwiftUI, quotas, usage-monitoring, SQLite, Hermes]
---

# macOS Quota Monitoring

Use this skill for native macOS utilities that display provider quota windows, reset timestamps, and local usage/accounting observed from Hermes Agent.

## Domain invariants

- A quota window is provider-owned data: do not derive official quota state from local token, request, cost, or accounting data.
- A verified reset transition is exactly `previous.usedPercent > 0`, `current.usedPercent == 0`, and `current.resetAt > previous.resetAt`.
- A repeated `0% → 0%`, missing reset timestamp, or non-advancing timestamp is not a reset.
- The first live observation after app launch establishes a baseline; do not emit a retroactive reset notification for a reset that happened while the app was stopped.
- Aggregate simultaneous reset events into one notification while retaining provider identity and every window label.
- Manual refresh remains a data-acquisition action, not a notification event by itself.

## Reset countdowns

- Treat `resetAt` as a snapshot timestamp, not a locally recalculated five-hour boundary.
- A relative-date UI will correctly count down before `resetAt`, but will count upward after it if the snapshot is stale. Never leave an expired snapshot presented as a valid future countdown.
- Refresh scheduling should be reasoned about separately from rendering. A general periodic refresh can be supplemented by a bounded, reset-aware refresh rather than globally shortening the interval or polling continuously.
- When a reset is due but the replacement snapshot has not arrived, preserve the last observed usage only if the UI clearly marks the data as updating/stale; do not display an increasing elapsed-time countdown as if it were the next reset.
- If the app remains running and a delayed live refresh proves the reset transition, process the normal reset detector. Reserve the no-retroactive-notification rule for the post-launch baseline.
- Provider/network failure after expiry must remain explicit and retryable; never invent a replacement `resetAt`.
- Diagnose a reported countdown reset in two layers: first verify whether the provider returned a new absolute `resetAt`; then inspect the display formatter. A formatter that rounds `ceil(remainingMinutes / 60)` can make `4h 00m 01s` appear as `5 h` without changing quota state.
- Keep countdown formatting in a testable Domain/Service temporal policy, not inside a SwiftUI view. Preserve seconds below one minute, minutes below one hour, and hours plus remaining minutes below 24 hours; avoid converting `23h 59m` to `1 g` before the 24-hour boundary.
- Derive hours and residual minutes from the original non-negative seconds value, not from an already rounded minute count. If minute ceiling would produce `60 min` in the final hour, normalize it without a discontinuity; verify `86399`, `86400`, and just-over-one-day values explicitly.

## SQLite accounting from Hermes

- Hermes `state.db` may be in WAL mode with `-wal` and `-shm` sidecars.
- On macOS, invoking the system `sqlite3` CLI with `-readonly` can fail to open a live WAL database. For a read-only application query, open normally and prepend `PRAGMA query_only=ON;` to the SQL command. This permits WAL reads while preventing writes.
- Add an integration regression test that creates a WAL-mode database and exercises the real reader path; a rollback-journal fixture does not cover this failure mode.
- Keep provider mapping explicit and test real provider identifiers from the database. Unknown providers should remain safely ignored rather than mapped to a guessed subscription.

## UI review and ticket capture

- For "Uso osservato da Hermes" sections, separate provider quota data from local accounting visually, keep values scannable, and make unavailable/stale states explicit.
- When the user asks for a quick ticket without grilling, create one issue immediately with the repository's `needs-grilling` workflow label, omit `ready-for-agent`, state the blocked/parked status, and do not start implementation or grilling.
- Use the domain glossary and issue template vocabulary; avoid embedding fragile file paths in tickets.

## Quota bar rendering

- On macOS, a native `ProgressView(value:total:)` draws a minimum leading fill cap at `usedPercent == 0`. Tinting that cap green or gray still communicates consumption even though the provider value is zero.
- A bare `ProgressView` with no `.tint` can inherit the system accent color. Keep an explicit tint decision at the quota-bar call site.
- For an exact provider-reported zero, `.tint(.clear)` hides the minimum fill cap while leaving the native groove visible. This preserves the control's native track, geometry, antialiasing, and padding with no custom drawing.
- Positive values keep the native `ProgressView` and the existing semantic tint. Apply the transparent branch only to exact `usedPercent == 0`; a positive fractional value keeps its semantic tint even if adjacent percentage text rounds to `0%`.
- Do not replace the zero state with a SwiftUI `Capsule` to imitate the track. Magnified runtime comparison showed different color, thickness, end shape, spacing, and lower-quality antialiasing compared with the native control.
- This app's quota bar palette is a documented contract (an ADR record): changing how empty-vs-fill colors map requires updating that ADR and the `CONTEXT.md` palette line, not just the view code. Read the applicable ADR before touching the palette.
- Runtime popover inspection is part of verification for tint/color changes; a diff review cannot catch environment-tint leakage. When live provider data has no zero window, install a temporary verification build that forces only the bar value and tint to the zero path, inspect it, then restore the real conditional and rebuild the final app.

```swift
ProgressView(value: window.usedPercent, total: 100)
    .tint(
        window.usedPercent == 0
            ? .clear
            : color(for: window, freshness: freshness)
    )
```

## Verification workflow

1. Inspect the provider snapshot schema and the actual runtime data before changing detection logic.
2. Write service/domain tests from the accepted transition and integration tests at repository/process boundaries.
3. Test countdown policy boundaries with independent literal expectations: negative/zero input, `59`, `60`, `3600`, `86399`, `86400`, and just-over-one-day values. This catches both coarse-hour rounding and premature day rollover.
4. Test stale, offline, restart-baseline, missing timestamp, equal timestamp, simultaneous-window, and normal usage-change paths.
5. For provider boundary changes, enumerate every wire shape and parallel adapter path, including alternate parsers, provider-specific transformations, persisted readers, and manual-reset payloads. Distinguish a missing field from a present empty field, and add a regression test for each distinction.
6. For SQLite changes, verify both a normal database and a WAL-mode database, then run the full Swift test suite.
7. Rebuild and launch the installed `.app` when the user asks for a runtime fix; verify the real database path and the app process.
- Keep unrelated working-tree changes out of the feature commit unless the user explicitly asks to include them. Before committing, run `git status` and look for pre-staged files you did NOT create — a sibling agent may be editing the same repo or even the same file. Commit only your own paths with a partial `git commit -- <paths>`, and re-read the file first if a `patch` diff shows content you didn't write (that means a concurrent writer overwrote you; confirm any referenced symbol is still defined before building).

## References

- See `references/hermesusage-monitoring-findings.md` for the validated provider/reset and WAL-accounting details from prior investigations.
