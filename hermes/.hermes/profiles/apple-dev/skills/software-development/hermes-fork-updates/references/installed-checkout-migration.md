# Installed-checkout migration checklist

Use this checklist before converting an installer-managed Hermes checkout to a fork-backed checkout.

## Backup and inspect

```bash
cd "${HERMES_HOME:-$HOME/.hermes}/hermes-agent"
git status --short --branch
git bundle create ~/hermes-agent-before-fork.bundle --all
git diff --binary > ~/hermes-agent-working-tree.patch
git status --short > ~/hermes-agent-status.txt
tar -czf ~/hermes-agent-untracked-before-fork.tar.gz $(git ls-files --others --exclude-standard)
```

Retain all existing stashes until the worktree and tests are verified.

## Configure remotes in the existing checkout

```bash
git remote rename origin upstream
git remote add origin git@github.com:USER/hermes-agent.git
git fetch upstream main
git fetch origin main
git remote -v
```

Expected roles: `origin` is the personal fork; `upstream` is `NousResearch/hermes-agent`.

## Commit local work deliberately

Do not run `git add -A` in a broad dirty tree. Group compatibility code and tests separately from desktop/TUI experiments. Verify `hermes usage --help` and `hermes usage --json` after each coherent commit.

## Rebase/update loop

```bash
git switch main
git fetch upstream main
git rebase upstream/main
hermes usage --help
hermes usage --json
git push --force-with-lease origin main
```

On conflict, resolve and continue or use `git rebase --abort`. Never push to the official upstream repository.

## Single-install verification

```bash
which hermes
head -30 "$(which hermes)"
python -c 'import os; print(os.environ.get("HERMES_HOME", "~/.hermes"))'
```

The command and virtualenv must still resolve to the original `$HERMES_HOME/hermes-agent`; data under `$HERMES_HOME` must not be recreated or moved.
