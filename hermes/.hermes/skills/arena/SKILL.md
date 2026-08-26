---
name: arena
description: Compare independent candidate solutions and synthesize the strongest shape.
disable-model-invocation: true
---

# Arena

Run independent candidate attempts against the same problem, compare whole shapes, and synthesize the strongest result. Use this for genuinely contested design, architecture, or implementation choices. Do not use it for deterministic mechanical edits.

## Procedure

1. Define the decision, constraints, caller usage, data shape, verification contract, and write fences.
2. Decide the number of candidates. Use at least two for a novel or contested architecture. Keep candidates structurally distinct.
3. Dispatch candidates with `delegate_task` in parallel. Give every worker the same grounded context and require a decision-rich artifact rather than a vague recommendation.
4. Keep parallel writes isolated with explicit git worktrees. Read candidate artifacts directly after completion.
5. Compare candidates on behavior, domain fit, public surface, ownership, dependency direction, reader load, invalid states, security, observability, complexity, migration risk, and verification cost.
6. Select a base and graft only justified parts of other candidates. Do not average incompatible designs.
7. Record the synthesis decision, rejected alternatives, and the principle that changed the choice.

## Hermes boundaries

Use `delegate_task`, not Cursor `Task` or `poteto-agent`. The parent owns synthesis and verification. Delegate self-reports are not proof.

## Verification

Before returning:

- candidates are genuinely distinct or the reason for fewer candidates is recorded;
- each candidate was evaluated against the same constraints;
- the selected shape has a concrete rationale;
- rejected alternatives have specific reasons;
- artifacts and diffs were inspected directly;
- no external or repository state was changed without explicit scope.
