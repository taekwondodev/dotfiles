---
name: dev-cycle-setup
description: Configure this repo for the dev-cycle skills — set up its issue tracker, triage label vocabulary, and domain doc layout. Run once before first use of triage, to-spec, to-tickets, implement, or wayfinder.
disable-model-invocation: true
---

# Dev Cycle Setup

Scaffold the per-repo configuration that `/triage`, `/to-spec`, `/to-tickets`, `/implement`, and `/wayfinder` assume:

- **Issue tracker** — where issues and tickets live
- **Triage labels** — the strings used for the five canonical triage roles
- **Domain docs** — where `CONTEXT.md` and ADRs live, and the consumer rules for reading them

This is a prompt-driven skill, not a deterministic script. Explore, present what you found, confirm with the user, then write.

## Process

### 1. Explore

Look at the current repo to understand its starting state. Read whatever exists; don't assume:

- `git remote -v` — is this a GitHub repo? Which one?
- `CLAUDE.md` — at `.claude/CLAUDE.md` or the repo root. Does it exist? Is there already a `## Dev cycle` section? If it exists and carries substantial prose beyond setup steps and pointers, flag it as a migration candidate for Section D.
- `CONTEXT.md` and `CONTEXT-MAP.md` at the repo root
- `docs/adr/` and any `src/*/docs/adr/` directories
- `docs/agents/` — does this skill's prior output already exist?
- Monorepo signals — a workspace manifest, or a populated `packages/*`/`crates/*` with its own `src/`. Present only in a genuinely large multi-package repo; their absence means single-context, which is almost every repo.

### 2. Present findings and ask

Summarise what's present and what's missing. Then take the sections in order — one section, one answer, then the next.

Lead each section with the recommended answer so the user can accept it in a word. Give a one-line explainer only when the choice genuinely branches; skip the section entirely when exploration already settled it.

**Section A — Issue tracker.**

> Explainer: this is where issues and tickets live for this repo. `/triage`, `/to-tickets`, `/to-spec`, and `/wayfinder` read from and write to it.

Default posture: if a `git remote` points at GitHub, propose GitHub Issues. Otherwise, propose personal Linear — never a local-markdown fallback (a wayfinder map needs a real tracker to show blocking edges visually).

- **GitHub Issues** — uses the `gh` CLI, native sub-issues and blocking
- **Linear** — for repos without a GitHub remote, or non-repo efforts

Record the choice in `docs/agents/issue-tracker.md`, seeded from [issue-tracker-github.md](./issue-tracker-github.md) or [issue-tracker-linear.md](./issue-tracker-linear.md).

**Section B — Triage label vocabulary.**

> Do you want to keep the default triage labels? (recommended: **yes**)

The defaults are the five canonical roles, each label string equal to its name: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. On **yes**, write them as-is from [triage-labels.md](./triage-labels.md). Only if the user says no — usually because their tracker already uses other names — collect the overrides so `/triage` applies existing labels instead of creating duplicates.

**Section C — Domain docs.** Default to **single-context** — one `CONTEXT.md` + `docs/adr/` at the repo root. This fits almost every repo; write it without asking.

Offer **multi-context** — a root `CONTEXT-MAP.md` pointing to per-context `CONTEXT.md` files — only when exploration found monorepo signals. Then confirm which layout they want.

**Section D — Existing `CLAUDE.md` content.** Only runs if Explore flagged a migration candidate; skip entirely otherwise.

> Explainer: before this setup, `CLAUDE.md` was doing the job `/domain-modeling` and ADRs now own — a place to dump domain terms and "why we built it this way" so you didn't have to repeat it every session. That content moves to where the rest of this pipeline expects to find it; `CLAUDE.md` goes back to being a pointer.

Read the existing file in full and sort each section into one of three buckets:

- **Operational/setup steps** ("run this command", "copy this file", "rename this") — stays in `CLAUDE.md` as-is.
- **ADR-worthy decision** — per `/domain-modeling`'s ADR test in ADR-FORMAT.md. Becomes a numbered ADR in `docs/adr/`, keeping the original rationale prose — that's the part worth preserving, not just the verdict.
- **Domain term** — a project-specific concept given a definition. Becomes a `CONTEXT.md` entry per CONTEXT-FORMAT.md.

Anything that doesn't clearly fit a bucket stays in `CLAUDE.md` — don't force a migration to hit a quota.

### 3. Confirm and edit

Show the user a draft of:

- The `## Dev cycle` block to add to `CLAUDE.md`
- The contents of `docs/agents/issue-tracker.md`, `docs/agents/domain.md`, and `docs/agents/triage-labels.md`
- If Section D ran: which section goes where — each one labelled operational/ADR/domain-term, the new ADR files' content, and the `CONTEXT.md` entries drafted from it

Let them edit before writing.

### 4. Write

Edit `CLAUDE.md` at whichever path it already lives at (`.claude/CLAUDE.md` or the repo root); create it at `.claude/CLAUDE.md` if it doesn't exist yet. If a `## Dev cycle` block already exists, update its contents in-place rather than appending a duplicate. Don't overwrite user edits to the surrounding sections.

If Section D ran: write the new ADR files and `CONTEXT.md` entries first, then rewrite `CLAUDE.md` — operational sections stay, migrated sections are replaced by a one-line pointer to where the content went (per `/writing-for-agents`' context-pointer rule — name what moved and where, don't restate it).

The block — pointers only, never the content itself:

```markdown
## Dev cycle

### Issue tracker

[one-line summary of where issues are tracked]. See `docs/agents/issue-tracker.md`.

### Triage labels

[one-line summary of the label vocabulary]. See `docs/agents/triage-labels.md`.

### Domain docs

[one-line summary of layout — "single-context" or "multi-context"]. See `docs/agents/domain.md`.
```

Then write the docs files using the seed templates in this skill folder as a starting point:

- [issue-tracker-github.md](./issue-tracker-github.md) — GitHub issue tracker, including the operations `/wayfinder` needs
- [issue-tracker-linear.md](./issue-tracker-linear.md) — Linear issue tracker, including the operations `/wayfinder` needs
- [triage-labels.md](./triage-labels.md) — label mapping
- [domain.md](./domain.md) — domain doc consumer rules + layout

### 5. Done

Tell the user the setup is complete and which skills will now read from these files. Mention they can edit `docs/agents/*.md` directly later — re-running this skill is only necessary if they want to switch issue trackers or restart from scratch.
