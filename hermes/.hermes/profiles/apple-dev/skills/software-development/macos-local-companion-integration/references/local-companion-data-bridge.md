# Local companion data bridges

Use this when a native app monitors another local agent/tool and shows `unavailable` despite the source app working.

## Investigation recipe

1. Resolve the source app's effective home/profile from its real environment, not from the app's assumed default.
2. Inventory actual producers: persistent database, generated files, CLI commands, in-memory state, and remote endpoints.
3. Run the source app's own usage/status command and capture a machine-readable result if one exists.
4. Compare expected paths with actual producer paths. Profile-local state and canonical/root state may differ.
5. Treat token/cost accounting and quota/rate-limit state as separate products. A session database may contain accounting while rate limits exist only in process memory or a provider endpoint.
6. Do not invent a JSON snapshot contract unless the source app writes it or a producer is implemented and tested.

## Bridge requirements

- Prefer a source-app CLI/export command reusing its existing authentication.
- Pass subprocess arguments as an array; never build a shell command containing secrets.
- Use read-only database access for SQLite sources.
- Drain or discard subprocess stderr and enforce a timeout; a hung child must not block UI refresh.
- Map technical provider identifiers to commercial subscriptions at the adapter boundary.
- Preserve explicit unavailable/error states for missing, malformed, unsupported, or unauthorized providers.
- Add secret-free fixture tests for command JSON and database schema, plus a live probe that verifies real output without printing credentials.

## Swift integration seam

Keep adapters behind `Sendable` source protocols. Inject fixture output or fake sources for tests; keep UI dependent on domain-facing results rather than Repository errors. For profile-aware sources, avoid summing shared quota windows and choose a documented reliability/timestamp winner.
