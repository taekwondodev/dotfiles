# Diagnostics: subagents fail instantly with "HTTP 404: model not found"

Symptom: a parallel fan-out (`delegate_task` with `tasks=[...]`) returns, per child, a
completion that is either empty or contains `HTTP 404: Model '...' not found` /
"The requested model does not exist" about a second after dispatch. All children fail
identically, in ~1–2s. This is a delegation *routing* misconfiguration, not a bug in the
task or the code being touched.

## Diagnosis

```bash
hermes config get delegation --json
```

The classic tell: `delegation.model` is empty **while** `delegation.provider` is pinned to
a provider that differs from the parent session's active model. When `delegation.model` is
blank, children inherit the parent session's model name but route it through the pinned
`delegation.provider` — so a model only served by provider A is sent to provider B and 404s.

Also compare the parent session's effective provider/model:

```bash
hermes config get model --json
```

Watch for the mismatch: parent `default/ provider` (e.g. `opencode-go` /
`deepseek-v4-flash`) vs delegation `provider` (e.g. `nous`). A `delegation.default` value
that hints at the intended model (`stealth/ox-alpha`) further confirms the provider was
switched intentionally but `delegation.model` was never filled.

## Fix

Make the three delegation keys consistent with the parent provider (or with a model the
pinned provider actually serves):

```bash
hermes config set delegation.provider <parent-provider>
hermes config set delegation.model    <model-that-provider-serves>
hermes config set delegation.base_url <parent-or-matching-base-url>
```

Example that resolved HermesUsageMonitor (parent `opencode-go` / `deepseek-v4-flash`):

```
delegation.provider = opencode-go
delegation.model    = deepseek-v4-flash-vision-exp
delegation.base_url = https://opencode.ai/zen/go/v1
```

`delegation.api_key` may stay empty when the provider authenticates from its env var
(e.g. `OPENCODE_GO_API_KEY`), which is already present.

## Smoke-test before re-fanning out

After changing config, dispatch a single trivial task ("reply with exactly the word OK")
before re-running the real parallel work. A child returning `OK` with status `completed`
proves the routing is live; only then re-issue the real review fan-out.

Note: config edits happen on disk immediately, but if a sub-process reads config at spawn
time, a fresh delegation picks the new values up without a restart.