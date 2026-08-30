# Desktop fork update detection (avoid the false "update available")

Use when the installed checkout is a private fork (`origin` = user's repo, `upstream` = official) and the Desktop keeps suggesting an update even though the local branch already contains all of `upstream/main`.

## Symptom

- Desktop toast/indicator bottom-right says an update is available "with unknown count".
- `git fetch upstream main && git rev-list --count HEAD..upstream/main` returns `0` (local is NOT behind) and/or `git merge-base --is-ancestor <upstream-tip> HEAD` exits `0` (local already contains the official tip).

## Root cause

The passive check for the "official source" path used:

1. `git ls-remote https://github.com/<owner>/<repo>.git refs/heads/<branch>` → returns the official tip SHA (works, anonymous).
2. GitHub compare API `GET /repos/<owner>/<repo>/compare/<currentSha>...<tip>` to recover an exact behind-count.

A private fork's local commit SHAs are **not objects in the official repository**, so that compare call returns **404**. The code treated any non-success as `null` ("update available, count unknown"), producing a false positive. It only ever works for installs whose HEAD SHAs exist in the official repo (direct installs).

## Verify it is a false positive

```bash
cd "$HERMES_HOME/hermes-agent"
git fetch upstream main
git rev-list --count HEAD..upstream/main          # 0 => not behind
git merge-base --is-ancestor "$(git rev-parse upstream/main)" HEAD && echo local-contains-official-tip
git ls-remote https://github.com/NousResearch/hermes-agent.git refs/heads/main
# Note: compare of fork sha...tip over HTTPS returns "404 Not Found".
```

## Fix pattern

Do not decide "behind" from the GitHub compare API at all — compute **local ancestry** after an anonymous HTTPS fetch into `FETCH_HEAD` (mirrors the ordinary `origin` path):

```text
git fetch --quiet <OFFICIAL_HTTPS_URL> main     # never SSH, so no FIDO2/passkey prompt
git rev-parse FETCH_HEAD                         # = target tip
git rev-list HEAD..FETCH_HEAD --count            # behind; >0 => offer update, 0 => none
```

When the official tip is already reachable from `HEAD` (local is equal or ahead), `behind == 0` and no update is offered. HTTPS fetch preserves the original design goal of the passive check (no SSH authentication prompt).

## Pitfalls

- Never default a compare-API failure (404/rate-limit/offline) to "update available": on a fork that is the guaranteed failure mode and yields permanent false positives. Compute count locally when the tip is available.
- Keep the anonymous-HTTPS fetch: fetching from the SSH remote would reintroduce the prompt the passive path exists to avoid.
