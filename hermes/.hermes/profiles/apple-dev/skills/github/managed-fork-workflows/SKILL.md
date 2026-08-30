---
name: managed-fork-workflows
description: "Use for managed fork installs with local commits."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux, windows]
metadata:
  hermes:
    tags: [git, github, fork, upstream, managed-install, rebase, migration]
    related_skills: [github-repo-management, github-auth, github-pr-workflow]
---

# Managed Fork Workflows

Use this skill when software was installed by an installer into a managed Git checkout, but the user needs to keep local commits while following the original project's default branch.

## Core model

Use one checkout and one runtime environment:

```text
origin   → user's fork (push target)
upstream → official repository (fetch-only source of truth)
main     → upstream/main plus the user's local commits
runtime  → the same checkout/venv used by the installed command
runtime data → outside the checkout (config, credentials, sessions, databases)
```

A fork does not eliminate conflicts. It changes them from opaque stash restoration failures into explicit, reviewable Git rebase conflicts.

## Migration sequence

1. **Discover before mutating.** Record the checkout path, active branch, remotes, HEAD, worktree status, stash list, installed command target, and runtime-data location.
2. **Create a verified backup.** Save a Git bundle, tracked working-tree patch, status/remotes/branches, and an archive of untracked files. Never assume a stash is the only backup.
3. **Inspect the dirty tree.** Separate intended code changes from generated files, credentials, local markers, and stale experiments. Do not publish secrets or machine-specific files to a public fork.
4. **Use a temporary migration worktree when possible.** Apply the complete local state there, turn intended changes into commits, and rebase the commit stack onto `upstream/main` before touching the installed checkout.
5. **Configure remotes.** Rename the official `origin` to `upstream`, add the personal fork as `origin`, fetch both, and set the upstream push URL to an unusable local value when accidental upstream pushes must be impossible.
6. **Commit local changes.** Prefer small topical commits. A large checkpoint commit is acceptable only as a recovery boundary; split it later.
7. **Rebase.** Run `git fetch upstream main` followed by `git rebase upstream/main`. On conflict, resolve explicitly or run `git rebase --abort`; do not delete files or roll back upstream automatically.
8. **Validate before publishing.** Run the project's startup/help checks, domain contract checks, and tests that exercise the local compatibility surface. A patch applying cleanly is not functional validation.
9. **Publish only to the fork.** Use `git push --force-with-lease origin main` after a successful rebase. Never push to the official remote.
10. **Verify the single-install invariant.** Confirm the installed command and virtual environment still resolve to the original checkout; confirm runtime data was not moved or rewritten; confirm no temporary worktree remains.

## Updating after migration

Use the fork-aware updater, not the original installer, for routine updates when the installer hard-codes the official repository. The updater should:

- fetch `upstream/main`, not only `origin/main`;
- compare `HEAD..upstream/main` before mutating the tree;
- report “already current” only for a successful no-update check;
- ask for confirmation when updates exist;
- stash only genuinely uncommitted changes and preserve the stash reference;
- rebase local commits onto `upstream/main`;
- validate the real command contract after the rebase;
- restore uncommitted changes without automatic deletion except for byte-identical duplicate untracked paths;
- abort the rebase and avoid pushing on validation or conflict failure;
- push the rebased branch only to `origin` with `--force-with-lease`;
- return concise human output by default and stable JSON with `--json`.

A successful `git apply` or rebase is not enough: validate the command that downstream software actually invokes. Distinguish `already-current`, `cancelled`, `ok`, and `partial-degradation` from `failed` fetch/validation states.

## Safety invariants

- Never include API keys, OAuth tokens, passwords, cookies, credential files, database contents, or secrets in commits, logs, reports, or summaries.
- Never use a public fork as a dumping ground for machine-specific untracked files.
- Never make the official remote a push target for convenience.
- Never use `git reset --hard` on the only copy of a dirty checkout; create a verified backup or disposable worktree first.
- Never describe a formal patch application as compatibility success without exercising the command contract.

## Reference

See `references/forked-managed-install.md` for the concrete migration checklist, remote commands, updater contract, and recovery cases.
