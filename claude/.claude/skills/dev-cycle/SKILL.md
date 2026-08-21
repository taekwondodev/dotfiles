---
name: dev-cycle
description: The canonical dev-cycle workflow, which is the one source of truth for capture-issue, grilling → to-spec → optional to-tickets → implement → code-review, its human checkpoints, and its invocation rules. Consult this skill before starting any phase of the cycle; other skills in the cycle point here instead of restating the workflow.
disable-model-invocation: true
---

# Dev Cycle: single source of truth

This skill **owns** the dev-cycle workflow. Other cycle skills (`grilling`, `to-spec`,
`to-tickets`, `implement`, `code-review`) point here instead of restating it. If two
files ever disagree about the workflow, this file wins. Fix the other file.

## The pipeline

The normal path is:

```
grilling ──► STOP (human checkpoint) ──► to-spec ──► to-tickets (if multiple slices) ──► implement ──► code-review ──► commit
```

A request may also be captured quickly before its requirements are fully explored:

```
capture-issue ──► needs-triage + needs-grilling ──► grilling ──► STOP ──► to-spec
```

`needs-grilling` is a workflow marker, not a replacement for the triage state labels. It means the issue is intentionally parked until a later user-invoked grilling session.

- **grilling**: interview the user to reach a shared understanding (design tree, rounds).
- **STOP**: the hard checkpoint. After the user confirms shared understanding, the agent
  **stops and hands off**: it reports the decisions and asks the user which phase comes
  next. It never proceeds on its own.
- **to-spec**: synthesize the conversation into a complete spec on the issue tracker. It may
  complete the same issue that `capture-issue` parked. No re-interview; if real gaps remain,
  run targeted grilling on just those gaps.
- **to-tickets**: when the spec needs multiple implementation slices, break it into tracer-bullet
  tickets with blocking edges and layers. A single-slice spec may go directly to `implement`.
- **implement**: build from the spec/tickets, tests against the spec's Testing Decisions.
- **code-review**: review before commit; a hard violation blocks the commit.

## Invocation rules (user-invoked)

Every phase after grilling is **user-invoked**: the agent must not auto-start `to-spec`,
`to-tickets`, `implement`, or `code-review`. The user triggers each phase explicitly.
The one exception is `code-review` at the end of `implement`. The implement skill calls
it as its closing gate before committing.

## Choosing the path

- **Task fits in one session** (the default): start with `grilling`, then STOP, then
  follow the pipeline. Do **not** chart a wayfinder map.
- **Task is genuinely too big for one session** (needs research, decisions that block in
  a chain, multiple bounded contexts): use `wayfinder` to chart a map, resolve decision
  tickets one per session, and hand off to `to-spec` when the frontier empties.
- **Starts small, grows big mid-grilling**: if the task starts in a single session but
  grilling surfaces fog the whole journey can't hold (external research, decisions that
  block in a chain, multiple bounded contexts), STOP mid-grilling and tell the user that
  it's wayfinder-sized, not grilling-sized. Don't keep interviewing into a task that
  needs a map.

## Hand-off wording

When a phase completes and the next one is user-invoked, the agent stops and says
something like: *"Phase complete. Decisions are [summary]. How do you want to proceed?
`to-spec` to formalize, `to-tickets` if the spec needs multiple slices, or `implement` directly?"*
The user chooses; the agent does not.
