---
name: dev-cycle-setup
description: Configure a repo for the dev-cycle skills. Produce one portable AGENTS.md from any existing agent-rule files, set up its issue tracker, issue-label vocabulary, and domain doc layout. Run once before first use of capture-issue, to-spec, to-tickets, implement, or wayfinder.
disable-model-invocation: true
---

# Dev Cycle Setup

Scaffold the per-repo configuration that `/capture-issue`, `/to-spec`, `/to-tickets`, `/implement`, and `/wayfinder` assume:

- **Issue tracker**: where issues and tickets live
- **Issue labels**: the strings used for the canonical category, state, and workflow-marker roles
- **Domain docs**: where `CONTEXT.md` and ADRs live, and the consumer rules for reading them
- **Project context**: one portable `AGENTS.md` at the repo root, produced from whatever agent-rule sources already exist

Read `writing-for-agents` before drafting the generated project context, domain, and tracker documents. Its general writing rules govern those documents; this skill adds only setup-specific structure.

This is a prompt-driven skill, not a deterministic script. Explore, present what you found, confirm with the user, then write.

## Process

### 1. Explore

Look at the current repo to understand its starting state. Read whatever exists; don't assume:

- `git remote -v`: is this a GitHub repo? Which one?
- `CONTEXT.md` and `CONTEXT-MAP.md` at the repo root
- `docs/adr/` and any `src/*/docs/adr/` directories
- `docs/agents/`: does this skill's prior output already exist?
- Monorepo signals: a workspace manifest, or a populated `packages/*`/`crates/*` with its own `src/`. Present only in a genuinely large multi-package repo; their absence means single-context, which is almost every repo.
- **Existing agent-rule sources**, searched across Git-tracked files at the repo root and at the conventional per-agent config directories, plus an explicit existence check for each known conventional path even when Git ignores it: `AGENTS.md` and `CLAUDE.md` at the repo root; `CLAUDE.md` in `.claude/`; `GEMINI.md` in `.gemini/`; `.hermes.md` and `HERMES.md` in `.hermes/`; `.cursorrules` and rules under `.cursor/rules/` only when they carry no path-scoped frontmatter; `.github/copilot-instructions.md`. Record each hit's path and read its full content. Treat a hit as repo-global only when its location gives it repository-wide scope. A rule file nested inside a package, subproject, or other subdirectory whose scope is that subtree only is directory-scoped: report it in the findings but exclude it from both the merge and the cleanup candidates, because broadening it to root would change its meaning. Never treat `AGENTS.override.md` as a merge source, and exclude every path-specific instruction file (any rules file whose frontmatter, name, or declared scope applies to selected paths rather than the whole repository). For each repo-global source found, check whether it already carries a `## Dev cycle` section; if it carries domain terms or architectural decisions beyond operational rules and pointers, flag it as a migration candidate for Section D.

For the known conventional paths above, check the filesystem directly even when the path is ignored by Git. Use tracked-file search only for additional recursive discovery, so dependencies, build output, and vendored copies are never treated as project rules.

### 2. Present findings and ask

Summarise what's present and what's missing. Then take the sections in order, one section and one answer at a time.

Lead each section with the recommended answer so the user can accept it in a word. Give a one-line explainer only when the choice genuinely branches; skip the section entirely when exploration already settled it.

**Section A0: Existing agent rules.** Only runs when Explore found at least one source.

> Explainer: the dev-cycle expects one portable `AGENTS.md` at the repo root. Whatever agent wrote the existing rule files, they are merged into it; the originals are left untouched until you approve cleanup at the end.

Take these steps before the other sections, because their output feeds Sections B through D:

1. Classify each repo-global source's content into three buckets: operational rules, domain terms, and architectural decisions. Use the same bucket tests as Section D.
2. Merge the operational content: deduplicate instructions that say the same thing in equivalent words, keep genuinely distinct rules side by side, and normalize Claude-specific references (`CLAUDE.md`, "Claude") to harness-neutral wording naming `AGENTS.md` or "the agent".
3. Surface every contradiction, whether it sits between two sources or inside one source (an old rule contradicting a newer one in the same file). Never pick by filename precedence or position. Show both excerpts and ask one focused question per conflict; write the user's decision into `AGENTS.md`.
4. Route domain terms to `CONTEXT.md` entries and architectural decisions to ADRs exactly as Section D specifies, then leave pointers in `AGENTS.md` instead of the migrated prose.
5. Draft `AGENTS.md` with: the merged operational rules, a `## Dev cycle` block per the template below, and pointers to `CONTEXT.md`, `docs/adr/`, and the `docs/agents/` documents.
6. Show the draft and let the user edit before writing. Then write `AGENTS.md` at the repo root.

**Section A: Issue tracker.**

> Explainer: this is where issues and tickets live for this repo. `/capture-issue`, `/to-tickets`, `/to-spec`, and `/wayfinder` read from and write to it.

Default posture: if a `git remote` points at GitHub, propose GitHub Issues. Otherwise, propose personal Linear. Never use a local-markdown fallback (a wayfinder map needs a real tracker to show blocking edges visually).

- **GitHub Issues**: uses the `gh` CLI, native sub-issues and blocking
- **Linear**: for repos without a GitHub remote, or non-repo efforts

Record the choice in `docs/agents/issue-tracker.md`, seeded from [issue-tracker-github.md](./issue-tracker-github.md) or [issue-tracker-linear.md](./issue-tracker-linear.md).

**Section B: Issue-label vocabulary.**

> Do you want to keep the default issue labels? (recommended: **yes**)

The defaults are the two canonical issue-state labels, each label string equal to its name: `needs-grilling` and `ready-for-agent`. On **yes**, write them as-is from [triage-labels.md](./triage-labels.md). Only collect the overrides if the user says no. Usually this is because their tracker already uses other names.

`needs-grilling` is the initial issue state for quick issues intentionally created before a grilling session. It is replaced by `ready-for-agent` when the complete spec is published.

**Section C: Domain docs.** Default to **single-context**. Use one `CONTEXT.md` + `docs/adr/` at the repo root. This fits almost every repo; write it without asking.

Offer **multi-context** only when exploration found monorepo signals: a root `CONTEXT-MAP.md` pointing to per-context `CONTEXT.md` files. Then confirm which layout they want.

**Section D: Existing rule-file content.** Only runs if Explore flagged a migration candidate; skip entirely otherwise.

Section D runs per flagged source whenever that source contains at least one domain term or one ADR-worthy decision; it does not wait for "substantial prose". Every domain term and architectural decision routed by Section A0 must land in `CONTEXT.md` or `docs/adr/` during this setup, so `AGENTS.md` never points at an artifact that was not written. If a routed artifact cannot be written, stop before writing `AGENTS.md` rather than leaving a dangling pointer.

> Explainer: before this setup, the old rule files were doing the job `/domain-modeling` and ADRs now own: a place to dump domain terms and "why we built it this way" so you didn't have to repeat it every session. That content moves to where the rest of this pipeline expects to find it; `AGENTS.md` keeps only operational rules and pointers.

Read each flagged source in full and sort each section into one of three buckets:

- **Operational/setup steps** ("run this command", "copy this file", "how to test"): merged into `AGENTS.md`.
- **ADR-worthy decision**: per `/domain-modeling`'s ADR test in ADR-FORMAT.md. Becomes a numbered ADR in `docs/adr/` while keeping the original rationale prose. That's the part worth preserving, not just the verdict.
- **Domain term**: a project-specific concept given a definition. Becomes a `CONTEXT.md` entry per CONTEXT-FORMAT.md.

Anything that doesn't clearly fit a bucket stays in `AGENTS.md`. Don't force a migration to hit a quota. When several sources carry the same bucket content, deduplicate during the merge rather than copying it twice.

### 3. Confirm and edit

Show the user a draft of:

- The generated `AGENTS.md`
- The contents of `docs/agents/issue-tracker.md`, `docs/agents/domain.md`, and `docs/agents/triage-labels.md`
- If Section D ran: which section goes where, each one labelled operational/ADR/domain-term, the new ADR files' content, and the `CONTEXT.md` entries drafted from it
- If any conflicts were found in Section A0: each conflict, both excerpts, and the user's recorded decision

Let them edit before writing.

### 4. Write

Write `AGENTS.md` at the repo root. The generated root `AGENTS.md` is this skill's deliverable, never a deletable source: it never appears on the cleanup list. If an `AGENTS.md` already existed at the root, its pre-existing content is preserved in version control before composition and its operational content is carried into the merge; the cleanup step may not delete it because deleting it would remove the deliverable itself. Do not modify any other agent-rule source file: the originals stay byte-for-byte unchanged until the cleanup step.

If Section D ran: write the new ADR files and `CONTEXT.md` entries first, then compose `AGENTS.md` with the operational rules plus one-line pointers to where migrated content went, per `/writing-for-agents`' context-pointer rule; name what moved and where, don't restate it.

The block contains pointers only, never the content itself:

```markdown
## Dev cycle

### Issue tracker

[one-line summary of where issues are tracked]. See `docs/agents/issue-tracker.md`.

### Issue labels

[one-line summary of the label vocabulary]. See `docs/agents/triage-labels.md`.

### Domain docs

[one-line summary of layout: "single-context" or "multi-context"]. See `docs/agents/domain.md`.
```

Then write the docs files using the seed templates in this skill folder as a starting point:

- [issue-tracker-github.md](./issue-tracker-github.md): GitHub issue tracker, including the operations `/wayfinder` needs
- [issue-tracker-linear.md](./issue-tracker-linear.md): Linear issue tracker, including the operations `/wayfinder` needs
- [triage-labels.md](./triage-labels.md): label mapping
- [domain.md](./domain.md): domain doc consumer rules + layout

### 5. Done

After everything is written and verified, offer optional cleanup of the superseded agent-rule sources:

1. List every discovered repo-global source file. Split the list in two: files proposed for deletion, and files retained (directory-scoped rules, files the user asked to keep, and any source the user excluded from the merge). Only the first list is deletable.
2. State clearly that deletion is irreversible and that `AGENTS.md` now carries the merged content.
3. Verify `AGENTS.md` exists and contains the merged result before proposing deletion.
4. Ask one yes/no question covering every file on the proposed-for-deletion list together. Never delete without an explicit yes, and never delete a retained file as part of that confirmation.
5. On confirmation, delete exactly the proposed-for-deletion originals in one operation and show the resulting repository status, including any retained files.

Then tell the user the setup is complete and which skills will now read from these files. Mention they can edit `docs/agents/*.md` and `AGENTS.md` directly later. Re-running this skill is only necessary if they want to switch issue trackers, redo the context merge, or restart from scratch.
