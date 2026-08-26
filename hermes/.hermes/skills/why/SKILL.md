---
name: why
description: Recover the rationale behind code, architecture, and past decisions.
disable-model-invocation: true
---

# Why

Recover the reason a system works the way it does. Treat rationale as evidence to reconstruct, not a story to invent. Use this skill when an existing choice may constrain a new design.

## When to Use

Use for:

- why a subsystem or dependency exists;
- why an architecture or boundary was chosen;
- regressions and historical behavior;
- ADR and issue rationale;
- non-obvious constraints.

Use `how` first when the current behavior is not understood. Use `architect` when the result becomes a new structural choice.

## Procedure

1. State the exact decision or behavior whose rationale is needed.
2. Inspect current code, `CONTEXT.md`, ADRs, README documents, issue bodies and comments, and relevant git history.
3. Separate explicit rationale from inference. Cite the source for each claim.
4. Check whether later changes invalidated the original rationale.
5. Report the strongest supported explanation, competing explanations, and remaining uncertainty.
6. Return durable rationale to the owning artifact, such as an ADR or spec, only when that write is part of the user's requested workflow.

## Verification

Before presenting the result:

- each rationale claim has an inspected source;
- facts and inferences are labelled separately;
- stale rationale is identified;
- no missing source is silently filled with a guess;
- no project state was modified unless explicitly requested.
