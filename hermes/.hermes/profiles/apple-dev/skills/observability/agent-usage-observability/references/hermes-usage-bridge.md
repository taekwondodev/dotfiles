# Hermes usage bridge notes

## Verified source map

- A profile-scoped `HERMES_HOME` can point to `~/.hermes/profiles/<name>`, while shared credentials and canonical accounting live under root `~/.hermes`.
- Durable accounting is in SQLite `state.db`, table `session_model_usage`. Useful fields include `billing_provider`, `model`, `api_call_count`, `input_tokens`, `output_tokens`, cache/reasoning tokens, and estimated/actual cost fields.
- Runtime quota/rate-limit data is not necessarily persisted in SQLite. Use a machine-readable Hermes bridge when available; do not invent a quota JSON file.
- Hermes Agent can expose a machine-readable provider snapshot through `hermes usage --json`. The app should run it in the canonical Hermes root context when profile-local env loading hides globally configured provider credentials.
- OpenCode Go API-key usage is available at `GET https://opencode.ai/zen/go/v1/usage` with both `Authorization: Bearer <key>` and `x-api-key: <key>`. The response contains `usage.rolling`, `usage.weekly`, and `usage.monthly`, each with `percent` and `resetsAt`.

## Safe probe pattern

1. Resolve the effective profile and canonical root separately.
2. Print only path existence, provider names, row counts, schema names, status, percentages, and timestamps. Never print keys or raw headers.
3. Verify the producer bridge directly before changing the UI:

```bash
HERMES_HOME="$HOME/.hermes" hermes usage --json \
  --provider nous --provider openai-codex --provider opencode-go
```

4. Query accounting read-only, using argument-separated SQL/process arguments and bounded subprocess timeouts. Discard or drain stderr so a child cannot deadlock on a full pipe.
5. Map technical provider slugs to commercial subscriptions at the domain boundary; preserve unknown/unavailable states rather than dropping them silently.

## Known interpretation

Local token counts are observed usage, not remaining entitlement. OpenCode Go quota percentages must come from its usage endpoint; never derive them from `state.db` tokens. If the provider key is unavailable in the active profile, check the root Hermes env/auth context rather than copying the secret into the app.
