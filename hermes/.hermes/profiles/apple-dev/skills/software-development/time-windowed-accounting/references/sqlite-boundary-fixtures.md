# SQLite Boundary Fixture Pattern

Use a fixed `AccountingWindow` ending at a literal test instant. Create a temporary `session_model_usage` table with `billing_provider`, `model`, token/request/cost columns, and nullable `last_seen`.

Seed rows for:

- a recent supported provider row;
- an exact start-boundary row;
- an older row that must be excluded;
- a future row that must be excluded;
- a NULL `last_seen` row that must be retained;
- multiple rows for one provider/model so filtering is proven to happen before `GROUP BY`.

Assert complete included metrics (tokens, requests, cost), absence of excluded contributions, both supported providers, and the existing query-only/read-only invariant. Use a Decimal tolerance for SQLite REAL cost sums instead of exact equality when several floating-point values are aggregated.

When editing multiline Swift SQL, use single Swift interpolation syntax `\(expression)` in the source. A double-escaped `\\(expression)` causes a Swift parse error rather than producing a literal interpolation.
