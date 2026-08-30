# ggshield / GitGuardian GitHub Actions workflow — grounded detail

Validated pattern for a direct-push repository: one blocking scan of the checked-out working
tree. Historical scanning is intentionally omitted unless the user explicitly requests it.

## Known-good workflow summary
- Triggers: `push` on the default branch plus `workflow_dispatch`.
- One `tree-gate` job with `contents: read`.
- `actions/checkout` with its normal depth; no `fetch-depth: 0` is needed.
- Install with `pip install --quiet ggshield`.
- Run `ggshield secret scan path . --recursive --yes`; a finding fails the job.
- Read `GITGUARDIAN_API_KEY` from a repository secret; never log or commit it.
- If JSON findings are useful, capture them only on gate failure and upload as an artifact with
  `actions: write`; do not add code-scanning/SARIF permissions unless the repository actually
  uses that integration.

## Decision tree
- **Scope**: standalone workflow or existing CI.
- **Scan scope**: current tree by default. Full history is opt-in and must not be the blocking
  gate; it may be run manually or as a separate non-blocking job when explicitly requested.
- **Fail behavior**: current-tree scan blocks the push gate.
- **Triggers**: push to the default branch plus manual dispatch.
- **Record**: decisions belong in `docs/adr/` when the repository uses ADRs.

## Hard pitfall
`ggshield secret scan repo .` scans full history and can fail forever after a historical secret,
even when the secret was removed. Do not put it in the normal push-fix-push gate. A follow-up
fix commit can heal a current-tree gate without rewriting history.

## gh CLI background facts
- `gh` has no push command; use `git push`.
- Resolve the workflow run by matching the pushed commit's `headSha`, not just the latest run.
- `gh run watch <run_id> --exit-status` blocks and propagates the CI result.
- For push-to-main workflows, poll briefly after pushing because the run may register later.
