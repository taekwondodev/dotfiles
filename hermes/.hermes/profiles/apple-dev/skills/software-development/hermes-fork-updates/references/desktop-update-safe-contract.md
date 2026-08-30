# Desktop `update-safe` contract

Use this reference when the installed checkout is also consumed by a Desktop or gateway updater.

## Remote roles

- If `upstream` exists, passive update checks and `update-safe` compare against `upstream/main`.
- `origin` remains the only push target and normally points to the user's private repository.
- If `upstream` is absent, an official single-remote install may compare against `origin/main`; it must not push as part of the update.
- Never infer the official source from the name `origin`; inspect the configured remote URL and prefer the official remote when present.

## Apply contract

Every Desktop apply path must invoke the same safe command, including POSIX handoff, Windows handoff, staged/bootstrap updater, and gateway-triggered updates:

```text
hermes update-safe --yes --json
```

The wrapper may use a bootstrap-only flag such as `--update` to select the staged installer mode. That flag must not be confused with the legacy CLI subcommand: the staged process still has to execute `update-safe` internally.

Rebuild or relaunch the Desktop only when the updater process exits successfully and its report status is `ok` or `already-current`. Do not treat `partial-degradation`, validation failure, rebase conflict, fetch failure, or push failure as a successful apply.

## Cross-platform validation

Validation runs inside the interpreter that launched `update-safe`. Build subprocess argv from `sys.executable` (or the equivalent current-runtime handle) and module invocations:

```text
<current-python> -m py_compile ...
<current-python> -m hermes_cli.main usage --json ...
```

Do not construct validation commands with a POSIX-only `venv/bin/...` path. A Windows venv uses `venv\\Scripts\\python.exe`; the regression test should inject a Windows-style interpreter path and assert the resulting argv.

## Verification probes

After a real update, verify all of the following:

1. The report says `status=ok` or `status=already-current`.
2. Usage/compatibility validation passed when an update was applied.
3. `git status --short --branch` is clean unless the user had deliberate local changes that were restored.
4. `git rev-list --count HEAD..upstream/main` is zero when `upstream` exists.
5. `git ls-remote origin refs/heads/main` matches the local branch after a successful fork sync.
6. The installed command and virtual environment still resolve to the same checkout.

A successful rebase may rewrite local commit IDs. Verify branch content, remote synchronization, and status rather than assuming an earlier local SHA remains unchanged.

## Security

Do not include API keys, tokens, passwords, cookies, credential files, usage payloads, or sensitive provider output in updater logs, UI, notifications, reports, or summaries. Redact sensitive lines before persisting or displaying errors.
