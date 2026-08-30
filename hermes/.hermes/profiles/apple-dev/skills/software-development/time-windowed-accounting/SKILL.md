---
name: time-windowed-accounting
description: Use when accounting needs a precise rolling time window.
---

# Time-Windowed Accounting

Use this class-level workflow when a product displays historical token, request, cost, usage, or other accounting values that need a meaningful period instead of an unbounded retained total.

## 1. Resolve the accounting contract first

Before editing code, pin down:

- window semantics: rolling duration, calendar period, or provider-aligned period;
- endpoint: refresh instant, provider reset, or another explicit boundary;
- whether the same window applies across providers/subscriptions;
- boundary inclusion (`>=`/`<=`), future timestamps, and missing timestamps;
- whether aggregated rows crossing the boundary are included in full or prorated;
- whether the UI exposes the period or keeps existing presentation.

Do not use app install/download time unless it is an explicit, reliable domain fact. Do not call an unbounded retained total a bounded period without either filtering it or documenting the assumption.

## 2. Put the rule in the right layers

- **Domain**: represent the window as a small value type with `start` and `end`; keep it independent of SwiftUI, SQLite, and provider SDKs.
- **Service**: own the clock and compute the window. Inject the clock so boundary tests are deterministic. Pass the explicit window through the existing accounting source port.
- **Repository**: apply timestamp filtering before aggregation. Keep SQL/data-source details here; do not filter in the Handler/UI after totals have already been computed.
- **Handler/UI**: render the already-windowed result. Do not invent timestamps, perform period arithmetic, or imply precision the source does not have.
- **Middleware**: observe windowed results without logging credentials or sensitive token contents.

For a child issue whose parent was classified as UI-only, update the child Layer(s) when real correctness requires Service/Repository work; preserve the same bounded context unless a new context is a deliberate decision.

## 3. Handle source differences explicitly

For SQLite-like sources with row timestamps:

- filter rows before `GROUP BY`;
- include rows at the start/end boundary according to the contract;
- exclude timestamps outside the closed interval, including future clock-skewed rows;
- decide explicitly whether `NULL` timestamps are included for compatibility;
- never prorate aggregated rows unless the source has enough detail to justify it.

For legacy payloads without timestamps, follow the product decision: either preserve them as assumed-in-window compatibility data or exclude them. Never fabricate a timestamp merely to make the model look complete.

Keep state stores read-only. A query-only/read-only safety mechanism must remain in place when reading live application databases, including WAL-backed SQLite databases.

## 4. Test at the highest valid seam

- Domain/Service unit tests cover window construction, injected-clock behavior, boundary inclusion, missing/future timestamp policy, and port propagation.
- Repository behavior uses integration fixtures, not Repository unit tests. Build a temporary database containing recent, exact-boundary, old, future, and null-timestamp rows; assert aggregate values independently from production logic.
- Include multiple providers/models and verify that filtering happens before aggregation, so excluded rows cannot leak into totals.
- Verify legacy no-timestamp payloads according to the chosen compatibility rule.
- Verify the database remains unchanged after reading.
- Do not add Handler unit tests merely to assert rendering details; preserve existing UI/layout verification when the presentation is intentionally unchanged.

Expected dates and metric values must be literal acceptance values or independently worked examples. Never compute expected values by calling the same helper under test.

## 5. Verification and delivery

Run targeted Domain/Service tests first, then the repository integration tests, then the complete suite and release build. Run `git diff --check` before committing.

If a multiline Swift SQL string fails to compile after adding interpolation, inspect escaping immediately: Swift interpolation inside a multiline string uses `\(expression)` in the source, not a double-escaped `\\(expression)`.

For sub-issues, verify the parent relationship, apply the repository's `ready-for-agent` label during spec publication, comment the implementation commit on the child issue, and close only the child after the final verification. Do not close the parent automatically.

## References

- `references/sqlite-boundary-fixtures.md` — compact fixture pattern for testing rolling accounting windows and read-only behavior.
