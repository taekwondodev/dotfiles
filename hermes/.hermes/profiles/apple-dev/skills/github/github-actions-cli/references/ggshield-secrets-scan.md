# GitGuardian / ggshield secrets-scan workflow pattern

Validated for repositories that push directly to `main`. The default is a single blocking
current-tree gate; no history job is created unless the user explicitly asks for one.

## Structure

- `tree-gate` job with `contents: read`.
- `actions/checkout` at default depth.
- `pip install --quiet ggshield`.
- `ggshield secret scan path . --recursive --yes` without `|| true`, so current-tree findings
  fail the run.
- Optional failure-only JSON artifact upload may require `actions: write`; keep that permission
  limited to the artifact-uploading job.
- API key is `${{ secrets.GITGUARDIAN_API_KEY }}` and must never be printed or committed.

## Scope policy

Do not add `fetch-depth: 0` or `ggshield secret scan repo .` to the normal gate. Full-history
scanning can keep a push-fix-push workflow permanently red because old secrets remain in git
history. If explicitly requested, run it manually or as a separate non-blocking job.

## Push loop wrapper

Use the repository's wrapper when available. The reliable sequence is:

1. Resolve the local branch HEAD SHA.
2. Push with `git push origin <branch>`.
3. Poll `gh run list --workflow "<name>" --branch <branch>` until a run matching that SHA
   appears.
4. Run `gh run watch <run_id> --exit-status`.

Matching `headSha` prevents watching an older run. `gh` authentication must be able to read
workflow checks.
