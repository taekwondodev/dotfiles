---
name: private-upstream-sync
description: "Use when mirroring a public upstream into a private repo."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux, windows]
metadata:
  hermes:
    tags: [git, github, private-mirror, upstream, fork, rebase, installers, updates]
---

# Private upstream sync

Use this skill when a user installed a Git-based tool or application from an official installer, then wants to keep personal modifications while following the original public repository without maintaining two local installations.

## Core model

Prefer one checkout and one runtime:

```text
origin   -> user's private repository (fetch/push)
upstream -> official public repository (fetch only)
local    -> one checked-out branch, normally main
runtime  -> the existing venv/binary/generated launcher
```

A GitHub public fork cannot be made private independently: fork visibility follows the upstream repository network. If privacy matters, create a separate private repository (a private mirror, not a GitHub fork), push the current branch there, switch the existing checkout's `origin`, and keep the official repository as `upstream`.

## Procedure

1. **Inspect before changing anything**
   - Locate the actual checkout used by the installed command (`command -v`, launcher, or install metadata).
   - Record branch, remotes, worktrees, status, shallow state, and current commit.
   - Confirm user data/config/credentials live outside the repository; never move or commit them.
2. **Back up the checkout**
   - Create a Git bundle, tracked working-tree patch, status/remote/branch records, and an archive of untracked files before any reset, cleanup, remote rewrite, or rebase.
   - Keep existing stashes until the migrated checkout is verified.
3. **Configure remotes**
   - Set `origin` to the user's private repository.
   - Add `upstream` for the official repository.
   - Set an invalid/private `pushurl` for `upstream` when accidental official pushes must be prevented.
4. **Make local changes commits**
   - Do not rely on a monolithic generated patch or repeated `stash pop` for durable customizations.
   - Commit local changes in coherent groups; keep accidental local markers, credentials, build artifacts, and unrelated experiments out of the private mirror unless explicitly wanted.
5. **Repair shallow installs**
   - Before pushing a complete history to a new private mirror, check `git rev-parse --is-shallow-repository`.
   - If true and full history is needed, run `git fetch --unshallow upstream main`, then run `git fsck --full --no-progress` and retry the push.
6. **Rebase and verify**
   - Fetch `upstream/main`.
   - Rebase the local branch onto `upstream/main`; resolve or abort conflicts explicitly.
   - Validate the real runtime contract after the rebase, not merely whether a patch command returned success.
   - Push only to `origin` with `--force-with-lease` when rebasing rewrote local commit IDs.
7. **Do not rerun the official curl installer blindly**
   - Managed installers often assume `origin` is the official repository and may pull/reset it. After switching to a private mirror, use the project's fork-aware updater or an explicit fetch/rebase workflow.
8. **Verify one-installation invariants**
   - The installed command still points to the same checkout and runtime.
   - `origin/main` matches local `main` after push.
   - `HEAD..upstream/main` is zero immediately after synchronization.
   - The private repository is actually private.
   - The old public fork is deleted only as a separate, explicitly authorized destructive operation.

## Updater integration

An updater for this model must compare against `upstream/main`, not only `origin/main`. It should rebase committed local changes, validate the command/application contract, and push to the private `origin`. If validation fails, restore the pre-update commit and do not push. If an updater has a desktop passive check, it must also prefer the `upstream` remote when present; otherwise it can incorrectly report the private mirror as current while upstream has new commits.

For an interactive CLI updater, use human output by default and an explicit JSON mode for automation. Distinguish: already current, cancelled, fetch failure, rebase conflict, validation failure, successful rebase/push, and push failure. Never describe a syntactically applied patch as functionally compatible without executing the contract check.

## Security and data boundaries

Never commit `~/.hermes` data, `.env`, OAuth tokens, `auth.json`, session databases, or runtime logs. A public-to-private migration does not replace credential rotation if a secret was ever committed. Remove obsolete local files that upstream explicitly removed instead of hiding them forever with `.git/info/exclude`, unless the file is confirmed user data and must be retained.

## References

- Migration commands, verification probes, and updater/desktop integration pitfalls: `references/private-upstream-install.md`.

## Pitfalls

- A GitHub fork is not the same as a private mirror; visibility cannot be changed on a public fork alone.
- A shallow checkout can fail when pushed as a full history; unshallow before diagnosing pack/object errors.
- `origin` being up to date says nothing about the official upstream after a private-mirror migration.
- A desktop update toast may use a separate Electron check path and may not invoke the CLI updater.
- Do not delete old public history until the private push and runtime verification have succeeded.
