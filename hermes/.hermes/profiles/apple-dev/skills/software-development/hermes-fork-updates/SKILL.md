---
name: hermes-fork-updates
description: "Use for Hermes fork updates."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux, windows]
metadata:
  hermes:
    tags: [hermes, git, fork, upstream, update, migration]
---

# Hermes fork-backed installed checkout

Use when Hermes was installed by `install.sh` into `$HERMES_HOME/hermes-agent` and the user wants the latest `NousResearch/hermes-agent/main` plus durable local modifications without two installations.

## Core invariant

Keep one code checkout and one virtual environment. Use `origin` for the user's fork and `upstream` for NousResearch. Keep Hermes data separate in `$HERMES_HOME`: config, auth, state.db, sessions, skills, and credentials must not be moved or recreated during code migration.

The installer-managed checkout is commonly `${HERMES_HOME:-$HOME/.hermes}/hermes-agent`. Changing Git remotes does not create another Hermes installation. After migration, verify `which hermes` and the wrapper/entrypoint still resolve to this checkout.

## Migration rules

1. Back up the current checkout before changing remotes: `git bundle create`, tracked binary diff, and an archive of untracked files. Retain existing stashes until recovery is verified.
2. Do not rerun the curl installer after changing `origin`: it treats `origin/$BRANCH` as the managed source and can pull/reset that checkout. Use Git plus the existing venv instead.
3. Rename the installer remote to `upstream`, add the user's fork as `origin`, and fetch both.
4. Separate compatibility changes, tests, desktop/TUI work, and experiments into small commits. Never use `git add -A` blindly in a broad dirty checkout.
5. Keep local changes as commits on the installed branch; do not rely on one monolithic stash/apply/restore patch.

See `references/installed-checkout-migration.md` for the commands and recovery checklist.

## Update rules

```bash
cd "${HERMES_HOME:-$HOME/.hermes}/hermes-agent"
git fetch upstream main
git switch main
git rebase upstream/main
hermes usage --help
hermes usage --json
git push --force-with-lease origin main
```

Resolve rebase conflicts explicitly with `git add` plus `git rebase --continue`, or abort with `git rebase --abort`. Never push to `NousResearch/hermes-agent`; pushing the rebased branch is only for the personal fork.

Existing Hermes fork-sync logic may intentionally skip automatic synchronization when `origin/main` contains local commits. That is safe but is not equivalent to rebasing. Do not call the installation current until the upstream fetch, rebase/merge, and compatibility checks pass.

## Validation and failure handling

A formal patch application is not sufficient evidence of compatibility. After any update, verify structure and behavior (`hermes usage --help`, `hermes usage --json`, and relevant tests). Distinguish update detected, already current, fetch failure/rate limit, rebase conflict, missing/failed compatibility command, and local restore conflict. Preserve a Git recovery point and local commits when validation fails; do not roll back upstream merely to protect local changes.

For an untracked stash collision, automatic cleanup is safe only when worktree and stash bytes are identical. For any other conflict, preserve the stash and report the exact paths.
