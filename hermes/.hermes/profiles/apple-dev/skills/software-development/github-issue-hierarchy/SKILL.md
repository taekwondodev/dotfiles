---
name: github-issue-hierarchy
description: "Use when linking GitHub issues into a parent/child tree."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [github, gh, issues, sub-issues, epic, parent, dependencies]
    category: software-development
    related_skills: [github, github-issues]
---

# GitHub Issue Hierarchy (parent / sub-issue / dependencies)

What this covers: turning a set of related GitHub issues into an **epic + sub-issues** tree, and wiring **dependency (blocked-by)** edges between issues. This is about *structure*, not issue CRUD (see `github` / `github-issues` for create/edit/close/label).

The native feature is **repo-scoped**: a repo either supports sub-issues or it doesn't, regardless of upstream. Always preflight before building.

## Preflight (once per repo)

```bash
gh auth status
gh --version        # sub-issue porcelain needs a recent gh (>= ~2.40)
# Is it enabled? An enabled-but-empty repo returns []: a 404/405 means disabled.
gh api repos/OWNER/REPO/issues/ANY_OPEN\_NUMBER/sub_issues --jq '.'
```

If sub-issues are disabled, fall back to the documented conventions: put the children in a task list in the parent body and prefix the child body with `Part of #<parent>`.

## Build the tree

Create the parent epic first (it's just an issue):

```bash
gh issue create --title "<epic title>" --body "..."   # → returns the new issue URL/#
```

Then attach children. Three equivalent entry points — pick the least typing:

```bash
# From a child: set its parent (one child per command)
gh issue edit <child> --parent <parent>

# From the parent: add several children at once
gh issue edit <parent> --add-sub-issue 9,11

# At creation time
gh issue create --title "..." --parent <parent>
```

Removal: `gh issue edit <child> --remove-parent` or `gh issue edit <parent> --remove-sub-issue <n>`.

## Verify BOTH directions (mandatory)

A single read tells you nothing about whether the link is fully formed. Read parent→child AND child→parent:

```bash
# parent -> children
gh api repos/OWNER/REPO/issues/<parent>/sub_issues --jq '.[] | "#\(.number) [\(.state)] \(.title)"'

# child -> parent
gh issue view <child> --json number,title,parent --jq '"#\(.number) parent: \(.parent.number // \"none\")"'
# progress rollup lives here too:
gh api repos/OWNER/REPO/issues/<parent> --jq '.sub_issues_summary'
```

Attaching a child NEVER changes the child's labels/state. A `needs-grilling` child stays `needs-grilling`; an epic doesn't make children implementable. If you rely on a child not being ready, that readiness lives on the child, not the link.

## Dependency (blocked-by) edges

Use native dependencies when your gh supports them, else fall back to a `Blocked by: #n, #n` line at the top of the child body.

```bash
# porcelain
gh issue edit <child> --add-blocked-by <blocker>   # accepts number or URL
# REST fallback (needs the blocker's DATABASE id, not #number or node_id)
gh api --method POST repos/OWNER/REPO/issues/<child>/dependencies/blocked_by \
  -F issue_id=$(gh api repos/OWNER/REPO/issues/<blocker> --jq .id)
```

Read-back: `gh api repos/OWNER/REPO/issues/<child> --jq '.issue_dependencies_summary.blocked_by'` — GitHub reports only OPEN blockers, so a ticket is unblocked when this hits 0/empty.

## Pitfalls

- `--parent` / `--add-sub-issue` / `--add-blocked-by` accept the issue **number or URL**; do NOT pass the database `.id` there. The DB id (from `--jq .id`) is only for the raw dependencies REST endpoint.
- Verify with a fresh `gh` read, never memory; credentials and repo state are read at the moment of the call.
- Trackers vary: this repo uses native sub-issues; others may use a task-list-in-parent convention. Check `AGENTS.md` / `docs/agents/issue-tracker.md` first.
- A parent epic is structurally just an issue — it carries no automatic scope semantics. Keep the epic body as a labelled scope statement and let children hold the actual work.

See `references/verified-session.md` for a worked example with exact commands and real output.
