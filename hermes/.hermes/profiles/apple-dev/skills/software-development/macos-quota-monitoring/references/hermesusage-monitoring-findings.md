# Validated HermesUsageMonitor findings

## Verified reset semantics

The accepted transition is `previous.usedPercent > 0`, `current.usedPercent == 0`, and `current.resetAt > previous.resetAt`. Missing or non-advancing reset timestamps and repeated zero observations are not reset events. The first live snapshot after launch is a baseline and does not emit retroactive notification.

## Verified WAL accounting issue

Hermes keeps `state.db` in WAL mode. On macOS, `/usr/bin/sqlite3 -readonly` can fail with exit 14 while opening a live WAL database. The validated safe read path is to open normally and prepend `PRAGMA query_only=ON;` to the SQL, then verify with an integration fixture that sets `PRAGMA journal_mode=WAL`.

## Ticket workflow preference

For an explicitly requested quick ticket without grilling, create the issue immediately with `needs-grilling`, keep it parked, omit `ready-for-agent`, and do not start implementation or the grilling phase.
