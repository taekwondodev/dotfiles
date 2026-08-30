# Manual-reset notifications and redemption (menu bar quota app)

Patterns for the "manual Full reset credits" feature of a ChatGPT/Codex quota menu
bar app: warning the user before credits expire, and letting them redeem one.

## Durable design threads

- Keep ALL layers (Service port, Repository adapter, Middleware observer) in one
  bounded context; the port is defined by the Service, the adapter implements it.
- Make every public type that crosses into the app/module target `public`, with an
  explicit `public init`. `any Foo?` must be spelled `(any Foo)?`. A protocol whose
  conformer must be constructed by an external composition root needs `public`.
- SwiftUI `#expect(await ...)` does NOT compile: the macro's autoclosure is
  non-async. Assign first: `let hit = await service.x(...); #expect(hit)`. Same for
  `#expect(try ...)` inside an autoclosure. This bit #35/#36 tests repeatedly.
- When a `public init` delegates to a designated init, do NOT assign stored
  `let`/`var` properties before the `self.init(...)` call (init rule). Build/pass
  dependencies through the designated init only.
- Actor + mutable state needs an `actor` (not a struct) to conform to a `Sendable`
  port with internal caching. `catch { cache = keys }` must log the error, not
  silently swallow it (fail-fast spirit, best-effort store).

## Expiration warning (once per local date)

- Group credits by the provider's **local calendar date** (inject `Calendar`, use
  UTC in tests so dates are stable). Offset hours must cross a real midnight to
  produce distinct-date test groups; pick `now` so 11h and 24h land on different days.
- A group is eligible when its **earliest** credit has <= 24h left and is not yet
  expired. >24h, expired, nil-expiration, non-plan-supported, redeemed, stale,
  unavailable, malformed -> never notify.
- Dedup key = `provider#local-date` only. Persist it (Application Support JSON) so a
  local date stays silent across restarts and a late-discovered credit on an already
  notified date does not re-notify. Assert in an integration test that no credit id /
  account / payload string is persisted.
- Record history ONLY after the notifier returns success. The Service source of
  truth: `recordOnlyAfterSuccessfulDelivery`.
- Evaluate eligibility only from a coherent **live** snapshot (the raw
  `read.manualReset`), gated on the refresh state being `.live`.
- Distinguish this from quota-window reset notifications: separate Service, port,
  observer, and OSLog category. Do not reuse the reset detector.
- No unit tests for the app/middleware notifier adapter (violates /testing). The
  "no-op outside an app bundle" behaviour is covered by a Service-level
  "delivery failed -> no record" test plus runtime bundle verification.

## Redemption (single remote write)

- The app is otherwise read-only; redemption is the ONE documented remote write
  (record in an ADR). All other pushes require a new decision.
- Verify the real upstream contract before coding: the provider's consume endpoint
  may not accept a credit id at all (body = fresh UUID idempotency key only, backend
  picks the credit). Do not build a wire payload around a spec assumption.
- Missing/ambiguous guard: when the upstream rejects unless a quota window is 100%
  used, replicate that guard locally (`usedPercent >= 100`) so a confirmation never
  fails for a not-exhausted reason.
- No force path. One user confirmation owns one idempotency key; a retry of the same
  unresolved attempt reuses it; a fresh confirmation after a coherent refresh makes a
  new key.
- Auth/HTTP errors are definite **rejection**, mapped separately from ambiguous
  outcomes (timeout/lost/malformed -> verification-required). HTTP status errors must
  NOT fall into the ambiguous bucket or they block all future redemption.
- Redemption-triggered refresh must suppress the generic quota-reset notification
  for that one observation (a `suppressing:` flag that also keeps the baseline fresh),
  so the user does not get a duplicate.
- Map bridge outcomes explicitly: `reset`/`already_redeemed` = success,
  `nothing_to_reset`/`no_credit` = not-consumed, auth/HTTP = rejected,
  unverified = block until coherent refresh.