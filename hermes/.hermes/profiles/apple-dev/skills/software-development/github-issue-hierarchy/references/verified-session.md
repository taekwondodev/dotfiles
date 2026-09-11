# Worked example: link #9 and #11 under a new parent epic

Repo: `taekwondodev/ProArtVolume`, gh 2.96.0, native sub-issues enabled.

## Preflight

```bash
gh auth status                      # Logged in to github.com account taekwondodev
gh --version                        # gh version 2.96.0
gh api repos/taekwondodev/ProArtVolume/issues/11/sub_issues --jq '.'   # [] → enabled, empty
gh api repos/taekwondodev/ProArtVolume --jq '.features'                # empty (features not a reliable probe)
```

Do NOT trust `.features` — it returned empty even though sub-issues work. The reliable probe is hitting `/sub_issues` and getting `[]` (not 404/405).

## Create the parent epic

```bash
gh issue create --title "Feedback di input non reattivo: latenza percepita su mute e OSD" \
  --body "..."
# → https://github.com/taekwondodev/ProArtVolume/issues/12
```

## Attach children

```bash
gh issue edit 9  --parent 12   # → https://github.com/taekwondodev/ProArtVolume/issues/9
gh issue edit 11 --parent 12   # → https://github.com/taekwondodev/ProArtVolume/issues/11
```

## Verify BOTH directions

```bash
# parent -> children (sub_issues endpoint)
gh api repos/taekwondodev/ProArtVolume/issues/12/sub_issues \
  --jq '.[] | "#\(.number) [\(.state)] \(.title)"'
# → #9 [open] Mute button: delay di applicazione, UX povera
# → #11 [open] OSD troppo lento: ottimizzare

# child -> parent, and rollup
gh issue view 9 --json number,title,parent --jq '"#\(.number) parent: \(.parent.number // \"none\")"'
# → issue #9 parent: 12
gh api repos/taekwondodev/ProArtVolume/issues/9 --jq '.sub_issues_summary'
# → {"completed":0,"percent_completed":0,"total":0}   (child-level rollup; use the PARENT issue for progress)
```

Both reads must agree. Here #9 and #11 each listed #12 as parent, and #12 listed both as sub-issues.

## Outcome notes

- Children kept their labels/state unchanged: both remained `enhancement`/`needs-grilling`.
- Neither child got `ready-for-agent` — the epic link alone does not make work implementable. Readiness stays on the child until its spec is complete.
- Decide or ask: if there is no existing parent that fits, creating a new epic is the natural move. Group by root cause, not by surface symptom.
