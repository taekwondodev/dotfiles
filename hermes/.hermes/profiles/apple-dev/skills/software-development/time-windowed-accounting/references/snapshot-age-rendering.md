# Snapshot-age rendering

Use this pattern when a macOS companion needs to answer how long ago a provider snapshot was captured without adding background work.

- Reference `capturedAt`, the provider-declared capture time; do not use app read time or install/download time.
- Render a relative label such as `Snapshot acquisito 12s fa`, `4 min fa`, `2 h fa`, or `1 g fa` when elapsed age is more useful than a calendar timestamp.
- Reuse the shared visible-popover clock already used by reset countdowns. Keep one 1 Hz UI timer only while the popover is open; cancel it on disappearance.
- Clamp zero/future timestamps to `appena acquisito`; never show negative ages.
- Keep snapshot age separate from freshness (`live`, `persisted`, `stale`).
- Test pure formatting with literal second/minute/hour/day values and future-clock skew; do not unit-test SwiftUI rendering details.