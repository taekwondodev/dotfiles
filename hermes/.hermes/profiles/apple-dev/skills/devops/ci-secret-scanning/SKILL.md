---
name: ci-secret-scanning
description: Add CI secret-leak scanning (ggshield/gitleaks).
---

# CI Secret Scanning

Add automated scanning for committed secrets/credentials to a repository's CI. The primary validated path is **ggshield (GitGuardian)** in GitHub Actions; the same decision tree and pitfalls apply to gitleaks, trufflehog, and detect-secrets.

## When to use
- User asks to "scan for secrets in the repo/CI", "integrate GitGuardian", or "fail CI on leaked credentials".
- Reviewing/designing a secrets-scan workflow for impacts (permanent-red risk, trigger coverage, permissions).

## Pre-flight facts to gather (don't ask the user)
Before any design/grilling, establish the environment yourself:
- Does a CI pipeline exist at all? `gh workflow list` and check for `.github/workflows/`. A project may have *zero* CI — then "add secret scanning to the CI" first means creating the pipeline or a standalone workflow.
- Is the default branch protected? `gh api repos/<owner>/<repo>/branches/<default>/protection` → HTTP 404 means unprotected (direct push allowed).
- Do repo/org secrets exist? `gh secret list`.
- `CONTEXT.md` / ADRs / AGENTS.md may constrain where decisions are recorded and whether the workflow must be read-only.

## Core workflow (ggshield, validated)

For the normal push gate, scan only the checked-out working tree. Do not add a full-history
job unless the user explicitly wants historical findings; historical findings are not useful
as a blocking gate and can keep iterative push-fix-push workflows red permanently.

```yaml
name: GitGuardian Secrets Scan
on:
  push: { branches: [main] }
  workflow_dispatch:
jobs:
  secrets:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v7
      - run: pip install --quiet ggshield
      - run: ggshield secret scan path . --recursive --yes
        env: { GITGUARDIAN_API_KEY: ${{ secrets.GITGUARDIAN_API_KEY }} }
```
See `references/ggshield-gitguardian-workflow.md` for the full grounded detail and the design-tree decisions.

## Decision tree (ask the user; surface the risk)
1. **Scope of what's created**: add secret scan to existing CI vs. create a standalone workflow vs. spec-only.
2. **Scan scope**: current tree is the default gate. Full-history scanning is opt-in only and should not be made a blocking job.
3. **Failure behavior**: blocking (job fails) vs. report-only (SARIF upload, never fail).
4. **SARIF upload** to GitHub Security tab (needs `security-events: write`) vs. logs only.

## Pitfalls (the ones that actually bite)
- **Full-history scan + push-to-main blocking fail = PERMANENT RED.** `ggshield secret scan repo` fails if ANY secret ever existed in history (even revoked/reverted). Do not add it to the normal push gate. If historical findings are explicitly requested, keep that job separate and non-blocking, or run it manually outside the workflow.
- **`on: workflow_call` alone never triggers.** A reusable workflow with only `workflow_call` has no caller and never runs. Pasting a reusable workflow into a fresh repo without the calling workflow silently does nothing.
- **`pip install ggshield` + `fetch-depth: 0`** — full history scan silently misses past commits without deep checkout.
- **`permissions: security-events: write`** is a narrow, ephemeral GITHUB_TOKEN scope for the job — it only authorizes writing code-scanning alerts (not code/branch/secrets) and dies at run end. Without it `upload-sarif` fails. Explain this when the user balks at "write".
- **Token placement**: personal repo → repository secret; org → org secret. There is no org secret for a user-owned repo. Name convention e.g. `GITGUARDIAN_API_KEY`.
- Add a `.gitguardian.yml` only when the checked-out tree needs exclusions (e.g. build artifacts, fixtures); gitignored/absent dirs don't need ignoring on a clean CI checkout.

## Verification
- Post a known-valid workflow: push triggers the current-tree gate (`workflow_dispatch` works headless) and a clean tree yields a green run. If main is unprotected and workflow uses push-trigger, CI runs in the background: monitor with `gh run watch <run_id> --exit-status` or use the repository's push-and-watch wrapper.
