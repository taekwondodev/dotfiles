# Hermes producer update resilience

Use this reference when HermesUsageMonitor loses all quota data after a Hermes Agent update.

## Root cause pattern

A locally-added machine-readable bridge can disappear after the Hermes checkout is fast-forwarded to upstream `main`. A stale/orphan commit is not evidence that the current executable supports the command. Probe the current executable before debugging Swift UI or decoding.

## Verified recovery sequence

1. Run a secret-free live probe against the current Hermes venv:

```bash
HERMES_HOME="$HOME/.hermes" "$HOME/.hermes/hermes-agent/venv/bin/hermes" usage --json \
  --provider nous --provider openai-codex --provider opencode-go
```

2. If the CLI reports `invalid choice: usage`, restore/reapply the producer-side compatibility change or update the app to an upstream-supported contract. Do not infer quota from historical tokens.
3. For a root-launched `.app`, search `~/.hermes/hermes-agent/venv/bin/hermes`; for a profile-launched development process, also resolve `~/.hermes/profiles/<profile>/../../hermes-agent/venv/bin/hermes`.
4. Use the canonical Hermes root as `HERMES_HOME` for account-global usage while retaining the active profile path for profile-local readers.
5. Inspect the real provider schema. OpenCode Go has been observed returning `usage.rolling`, `usage.weekly`, and `usage.monthly`, each with `percent` and `resetsAt`; its endpoint requires both `Authorization: Bearer` and `x-api-key`.
6. Preserve healthy providers and map only the broken source to explicit unavailable diagnostics.

## Update policy

Upstream Hermes `main` is the source of truth. Compatibility patches should live outside the upstream repository and be re-applied only while upstream lacks the contract. Future update-safe tooling should preserve local changes, update `main`, test the usage command, write a non-sensitive local report under `~/.hermes/update-safe/`, and never push upstream or write credentials/state databases.

Never print API keys, authorization headers, cookies, prompts, transcripts, or raw database rows in probes or reports.
