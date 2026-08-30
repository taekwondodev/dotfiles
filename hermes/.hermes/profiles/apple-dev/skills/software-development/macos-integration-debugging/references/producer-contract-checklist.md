# Producer Contract Checklist

Use this checklist before changing a macOS UI that reports data from a local CLI, profile system, database, or agent runtime.

## Hermes-style profile/root split

- Resolve the effective profile root from `HERMES_HOME`.
- Separately resolve the canonical root when `HERMES_HOME` is `~/.hermes/profiles/<name>`.
- Keep profile configuration/auth context separate from shared accounting/state when the producer does.
- Never print environment values that may contain credentials; print only variable presence and safe paths.

## Producer verification

1. Check candidate artifacts for existence and type.
2. Search the producer source for the writer and schema.
3. Prefer a producer-owned machine-readable command/export over an invented JSON file.
4. If using SQLite, identify the exact schema and open it read-only.
5. Preserve missing, malformed, unsupported, and unavailable states; do not collapse them into an empty collection.

## Subprocess bridge safety

- Pass executable arguments as an argument array; never build a shell command string with secrets or paths.
- Drain or discard stderr so a child cannot deadlock on a full pipe.
- Use a bounded timeout and terminate the child on expiry.
- Treat non-zero exit status and invalid JSON as an explicit unavailable result.
- Keep subprocess output out of logs unless it has been sanitized.

## Usage versus entitlement

- Local token/request/cost records are observed usage, not remaining quota.
- Remote quota percentages must come from a verified provider or producer-owned usage endpoint.
- Do not derive a quota percentage from local tokens without an explicit limit and reset contract.
- Map technical provider slugs to commercial subscriptions at the domain boundary.

## Hermes/OpenCode example

A verified Hermes bridge can run from the canonical root context:

```bash
HERMES_HOME="$HOME/.hermes" hermes usage --json \
  --provider nous --provider openai-codex --provider opencode-go
```

For OpenCode Go's API-key usage endpoint, both `Authorization: Bearer <key>` and `x-api-key: <key>` are required. Read the key through Hermes' credential environment; never copy it into app configuration, fixtures, logs, or UI.
