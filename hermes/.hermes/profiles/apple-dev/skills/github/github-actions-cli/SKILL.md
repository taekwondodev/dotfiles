---
name: github-actions-cli
description: "Use when waiting on CI or designing CI gates from gh CLI."
---

# GitHub Actions from the CLI, and recoverable CI gates

For working a repository that pushes directly to main (no PR workflow) and for designing CI
gates that an agent can iterate against. Apply after any push-to-main change or when asked
to "push and wait for CI" or to add a secrets-scan gate.

## Verified gh facts (gh 2.96.0)

- `gh` has no `push`. For an HTTPS remote, run `gh auth setup-git` once so git uses the gh
  token as a credential helper, then `git push` normally. An SSH remote pushes with your key,
  nothing extra needed.
- `gh repo sync` fast-forwards the default branch from a source repo (forks/upstream); it
  does not push your commits. Not a push command.
- Nothing waits on CI by itself: `gh pr create` returns immediately.
- Blocking wait: `gh run watch <run-id> --exit-status` blocks until the run finishes and
  exits non-zero if the run failed. Use this to turn a CI result into a script/agent exit
  status.
- Check polling: `gh pr checks` returns once (exit code 8 if pending); `gh pr checks --watch`
  is the only flag that blocks and refreshes (default 10s, `--fail-fast`).
- `gh pr merge` has no `--wait` flag in recent versions; use `--auto` to merge only when
  required checks pass.
- `gh run watch` needs auth that can read checks: an OAuth or classic personal access token.
  A fine-grained PAT cannot carry the `checks:read` permission, so it will not work.

## Push-and-watch loop (direct push to main, no PR)

1. Record the HEAD sha before pushing.
2. `git push origin <branch>`.
3. Resolve the run for the pushed commit, polling briefly because the run registers a moment
   after the push:
   `gh run list --workflow "<name>" --branch <branch> --limit 10 --json databaseId,headSha --jq '.[] | select(.headSha == "<sha>") | .databaseId' | head -1`
   Matching by `headSha` (not just "latest run") avoids watching a stale earlier run.
4. `gh run watch "$run_id" --exit-status` and exit with its status.

This loop recovers on its own for a fix commit, but only if the gate is designed for it (see
below).

## Recoverable CI gate design

- A blocking gate on the **full git history** is unrecoverable in a push loop: a commit
  containing a problem (e.g. a secret) stays in history forever, so even a follow-up fix
  commit leaves the run red until you rewrite history or suppress the incident. Do not gate
  on history for an iterative push-fix-push workflow.
- Make the **current working tree** the blocking gate: a fix commit removes the problem from
  the tree and flips the run green again.
- Do not add a history-report job by default. Historical scanning is an explicit opt-in and,
  if enabled, must remain separate and non-blocking or be run manually outside the push gate.

## Secrets-scan (ggshield) workflow pattern

See `references/ggshield-secrets-scan.md` for action-version facts. The default pattern is a
current-tree gate: checkout normally (no `fetch-depth: 0`), install ggshield, and run
`ggshield secret scan path . --recursive --yes` with the repository API secret. Do not add a
full-history job unless explicitly requested; if enabled, keep it non-blocking or manual.

## Pitfalls

- Omit `--workflow` on `gh run list` and you may resolve another workflow's run.
- Do not add local checks (build/test) inside the push loop unless asked; keep it push-then-watch.
- A fix commit keeps the broken commit in history, so refuse to let a "history" gate be the
  blocker if the user wants an agent-driven iterative loop.

## Verification

After landing a gate workflow, run the loop once and confirm the exit status is zero on a
clean tree and non-zero when a planted fake (non-sensitive) secret is present. Pull the
latest action version tags with `gh api repos/<owner>/<action>/tags --jq '.[].name'` before
pinning an action.