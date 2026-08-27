---
name: implement
description: "Implement a piece of work based on a spec or set of tickets, writing tests against the spec's Testing Decisions and closing out with /code-review before committing."
disable-model-invocation: true
---

Implement the work described by the user in the spec or ticket.

**This step is user-invoked**: do not start it on your own. The user triggers it explicitly (normally by approving a spec or tickets, after grilling/to-spec/to-tickets). The pipeline, its checkpoints, and the invocation rules live in the `dev-cycle` skill; read it before proceeding.

Read the ticket's **Layer(s)** line first (`/to-tickets` sets it). It tells you which of `/architect`'s Handler/Service/Repository/Middleware layers this touches before you open a single file.

**Read the standards FIRST, before opening any file**: load the `coding-standards`, `architect`, and `testing` skills and keep their bodies in context for the whole implementation. Their titles in the index are not enough: the rules live in the bodies (TyDD, dependency direction, secure defaults, layer placement, test seams), and skills load lazily, so you must read them explicitly or they never enter context. Apply them while you write, not just at review time: place new code in the layer the ticket names, wire it through the port the layer already exposes, and apply `/coding-standards`' TyDD/dependency/secure-defaults rules as you write each piece. Do not defer this to `/code-review` to catch after the fact (the review's Standards axis loads the same skills and judges against them, so anything you skip here surfaces there as rework).

Write tests alongside the implementation, at the seams `/testing` allows. Take expected values from the spec/ticket's Testing Decisions or acceptance criteria. Never invent them from the same reasoning that produced the implementation; that's the self-graded anti-pattern in `/testing`'s Test quality section. Layers outside `/testing`'s scope get integration coverage instead. Never bend a unit test to reach them.

## Modes, capabilities, and principles

When the ticket crosses a boundary, use the `/architect` sketch and its threat-model decisions as the implementation contract. Load the canonical owner when its trigger fires:

- For a bug fix, use `investigation` and `principle-fix-root-causes`: reproduce before editing, trace the mechanism, add the smallest regression proof, then fix the owning cause.
- For a refactoring, use `blast-radius`, `principle-subtract-before-you-add`, and `principle-migrate-callers-then-delete-legacy-apis`: pin behavior, remove dead weight, migrate every caller, and verify equivalence.
- For a performance issue, use `perf-issue`; for repeated metric work, use `hillclimb`. Preserve the realistic workload, baseline, regression gate, and measured verdict.
- Use `principle-build-the-lever` when a focused script, transform, or harness makes non-trivial work safer or reviewable.
- Use `principle-sequence-verifiable-units` to split the implementation into todo items that each finish in an observable state.
- Use `principle-prove-it-works` to choose a check against the real artifact rather than compilation or a delegated self-report.
- Apply the canonical domain, type, boundary, idempotence, and migration principles named by `/architect` when their triggers fire; each must change a type, owner, boundary, operation, or verification step.

Record the changed behavior for every applied principle. Do not add a principle list that has no effect on the implementation or its checks.

Run typechecking regularly, single test files regularly, and the full test suite once at the end. When the suite is long or slow, dispatch it as a sub-agent and read its output rather than blocking the session inline.

When closing a ticket unblocks new frontier tickets (per `docs/agents/issue-tracker.md`), **ask** the user whether to dispatch a sub-agent to implement one of them in parallel. Never spawn it without asking first.

Once done, read the `code-review` skill and review the work against this ticket, with `git rev-parse` of the ticket's starting commit as the fixed point. Its Standards axis independently judges the tests you wrote, catching what a self-graded pass would miss. A hard `coding-standards`/`architect` violation or a missing Spec requirement blocks the commit. Fix it and re-review; do not commit around it.

Commit your work to the current branch, then close the ticket per `docs/agents/issue-tracker.md`'s tracer-bullet operations.
