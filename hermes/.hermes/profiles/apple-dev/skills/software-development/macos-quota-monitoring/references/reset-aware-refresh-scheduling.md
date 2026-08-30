# Reset-aware refresh scheduling

Validated design decisions for a macOS quota monitor whose provider `resetAt` can expire between periodic refreshes.

## Scheduling contract

- Keep the general refresh cadence at 15 minutes.
- From live snapshots only, find the nearest future `resetAt` across all subscriptions and quota windows.
- Schedule one shared refresh 2 seconds after that timestamp.
- Rebuild the schedule after every live snapshot; discard timers for removed windows, missing timestamps, or superseded timestamps.
- Deduplicate periodic, reset-aware, and manual triggers behind one in-flight acquisition.

## Retry contract

- If the reset-aware refresh fails or still returns the expired timestamp, schedule one shared retry after 30 seconds.
- After that retry, stop rapid retries and defer to the normal 15-minute cadence.
- If a post-refresh snapshot already contains an expired timestamp, do not trigger an immediate cascade.
- On app restart, perform the normal immediate refresh; its first live snapshot is a baseline and must not cause a retroactive reset notification.

## UI contract

- Before expiry, display the provider reset using the relative date.
- Once expired while a reset-aware refresh is pending, do not let the relative date display elapsed time (`1s`, `2s`, ...). Keep the last usage visible and show an explicit `Aggiornamento quota...` state for the reset.
- If the refresh/retry fails, preserve the last usage as stale when available and show the existing `Quota non disponibile` reset state. Never derive a replacement timestamp locally.

## Verification cases

Cover service/domain behavior for nearest-deadline selection, 2-second offset, shared refresh, timer replacement, one 30-second retry, no immediate cascade, and exclusion of stale/persisted snapshots. Verify the handler/UI seam for the updating state, no increasing countdown, successful replacement snapshot, stale fallback, and no concurrent acquisition.
