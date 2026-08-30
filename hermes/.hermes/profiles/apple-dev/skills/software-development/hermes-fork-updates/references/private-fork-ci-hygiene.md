# Silencing inherited CI on a private Hermes fork

A private fork inherits all of upstream's `.github/workflows/*`. Every push (or push to `main`) then re-runs the whole CI suite, which assumes the official repo's environment and secrets, so the fork floods with failing runs. This reference keeps the fork quiet without deleting upstream files (so `update-safe` rebases cleanly).

## Disable GitHub Actions entirely (no file change)

```bash
gh api --method PUT "repos/<owner>/<repo>/actions/permissions" -f enabled=false
gh api "repos/<owner>/<repo>/actions/permissions"   # verify: {"enabled":false}
```

This is a repository setting, not a git change — `.github/workflows/*` stay byte-for-byte aligned with upstream and `update-safe`/rebase are unaffected.

Cancel runs already in flight (some stay `in_progress` for a while; loop until none):

```bash
for i in 1 2 3; do
  ids=$(gh run list --repo <owner>/<repo> --limit 100 --json databaseId,status \
        --jq '.[] | select(.status=="in_progress" or .status=="queued" or .status=="pending") | .databaseId')
  [ -z "$ids" ] && break
  while IFS= read -r id; do [ -n "$id" ] && gh run cancel "$id" --repo <owner>/<repo> >/dev/null; done <<<"$ids"
  sleep 2
done
```

## Dependabot

Two independent mechanisms, disabled independently:

- **Security fixes**: separate REST toggle.
  ```bash
  gh api "repos/<owner>/<repo>/automated-security-fixes"      # {enabled, paused}
  ```
  `GET /repos/.../vulnerability-alerts` returns 404 when alerts are disabled; that is expected, not an error.

- **Scheduled version-update PRs** (the weekly `github-actions` config in `.github/dependabot.yml`): there is **no REST toggle** for this. The only way to stop them while keeping the file in the tree is a deliberate local divergence:

  ```yaml
  updates:
    - package-ecosystem: "github-actions"
      ...
      open-pull-requests-limit: 0
  ```

  Trade-off: `.github/dependabot.yml` then differs from `upstream/main` by one intentional line. `update-safe` preserves that commit across rebases; if upstream edits the same file, the rebase may require a manual conflict resolution (safe: it aborts as `partial-degradation`, no Desktop rebuild).

- Close any PRs Dependabot already opened: `gh pr list --repo <owner>/<repo> --author app/dependabot --state open`, then `gh pr close N`.

## Recommendation

Prefer disabling Actions at repo level + `open-pull-requests-limit: 0` over deleting `.github/workflows/*` or `.github/dependabot.yml`: deletion diverges far more from upstream and churns on every rebase. A one-line `dependabot.yml` divergence is the smallest, most legible local override.
