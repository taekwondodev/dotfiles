---
name: dev-cycle
description: Route development work through principles, capabilities, and verified delivery.
disable-model-invocation: true
---

# Dev Cycle

`dev-cycle` is the normal entrypoint for development work. It reads the task, selects a primary mode, activates the capabilities that mode needs, and keeps the work moving toward a verified result. Existing phase and specialist skills remain directly invocable.

This skill is the routing and coordination source of truth. It does not copy the detailed procedures owned by `grilling`, `architect`, `to-spec`, `to-tickets`, `implement`, `code-review`, `wayfinder`, `handoff`, or `writing-for-agents`.

## Sticky task mode

Treat `dev-cycle` as active for the current task across turns.

- `continue` resumes the current mode and phase.
- `new task` resets classification and starts a new task.
- Hermes `/new` creates a fresh session.
- A direct invocation of another skill overrides the current step for that request without silently changing the task's recorded state.

Keep the current task, primary mode, active capabilities, decisions, evidence, and next completion criterion visible in the todo list or handoff artifact when the work spans turns.

## Non-negotiables

- Read the applicable principles before acting.
- Separate facts, hypotheses, decisions, and actions.
- Investigate observable facts before asking the user for them.
- Use `architect` when a change can lock in a wrong shape, boundary, ownership model, or public contract.
- Use `clarify` for decisions the user owns, not for facts tools can establish.
- Preserve the human checkpoint after grilling for product and scope decisions.
- `architect` itself has no automatic checkpoint. It proceeds unless the user explicitly asks it to stop.
- Do not declare success from a self-report, compilation alone, or a proxy observation.
- Preserve the single source of truth for every rule. `unslop` belongs only to `writing-for-agents`. The no-comments rule belongs only to `coding-standards`.
- Do not add a test methodology that the task does not require.

## Principles index

Use the complete canonical principle skill when its trigger fires. The short index below is the routing summary and follows the pstack formulation.

### Core

- **Laziness Protocol** (`principle-laziness-protocol`). Bias toward deletion and the smallest change that solves the problem.
- **Foundational Thinking** (`principle-foundational-thinking`). Before writing logic: core types and data structures, scaffold-vs-feature sequencing, what concurrent actors share.
- **Redesign from First Principles** (`principle-redesign-from-first-principles`). Redesign as if the requirement had been foundational from day one.
- **Subtract Before You Add** (`principle-subtract-before-you-add`). Remove dead weight, redundant validators, and stub references first, then build on the simpler base.
- **Minimize Reader Load** (`principle-minimize-reader-load`). Count layers between question and answer, and hidden state in the reader's head; collapse one-caller wrappers and shrink mutable scope.
- **Outcome-Oriented Execution** (`principle-outcome-oriented-execution`). Planned rewrites and migrations converge on the target architecture instead of preserving throwaway compatibility states.
- **Experience First** (`principle-experience-first`). Choose user delight over implementation convenience; ship fewer polished features over more rough ones.
- **Exhaust the Design Space** (`principle-exhaust-the-design-space`). A novel interaction or architectural decision gets 2-3 competing prototypes before commitment.
- **Build the Lever** (`principle-build-the-lever`). For non-trivial work, build the tool that does or proves it instead of working by hand.

### Architecture

- **Model the Domain** (`principle-model-the-domain`). Encode the domain in a structure instead of scattered conditionals.
- **Boundary Discipline** (`principle-boundary-discipline`). Concentrate guards at system boundaries; trust internal types and keep business logic pure.
- **Type System Discipline** (`principle-type-system-discipline`). Make illegal states unrepresentable, brand semantic primitives, and parse external data at boundaries.
- **Make Operations Idempotent** (`principle-make-operations-idempotent`). Converge to the same end state regardless of partial prior runs.
- **Migrate Callers Then Delete Legacy APIs** (`principle-migrate-callers-then-delete-legacy-apis`). Migrate callers and delete the old API in the same wave.
- **Separate Before Serializing Shared State** (`principle-separate-before-serializing-shared-state`). Eliminate sharing first; serialize only when one shared writer is a real invariant.

### Verification

- **Prove It Works** (`principle-prove-it-works`). Verify against the real artifact, not a proxy, self-report, or “it compiles.”
- **Fix Root Causes** (`principle-fix-root-causes`). Trace each symptom to its root cause and fix it there; reproduce first.
- **Sequence Verifiable Units** (`principle-sequence-verifiable-units`). Break multi-step work into small units that each end in a checkable state.

### Delegation

- **Guard the Context Window** (`principle-guard-the-context-window`). Route bulk to subagents and keep summaries in the main thread.
- **Never Block on the Human** (`principle-never-block-on-the-human`). Proceed on observable facts and reversible preparation; stop for product, scope, architecture, contract, security, and other human-owned decisions.

### Meta

- **Encode Lessons in Structure** (`principle-encode-lessons-in-structure`). Encode recurring corrections as lint, metadata, runtime checks, scripts, or skills instead of repeating prose.

When a principle influences a choice, record the principle and the changed choice. A principle name without a decision is not evidence of application.

## Classify the task

Choose one primary mode and add secondary capabilities as needed. Do not force a mixed task into one category.

### Investigation

Use for a read-only question or an unknown cause.

```text
dev-cycle why does X continue to work?
→ grilling
→ how or why
→ investigation
→ decision questions only after evidence
```

### Feature

Use for new or changed behavior. Route through `grilling`, then the governed feature path:

```text
grilling
→ product and scope decisions
→ checkpoint
→ to-spec
→ to-tickets when needed
→ implement
→ code-review
```

Activate `architect` when the feature crosses a boundary or changes a shape or contract.

### Bug fix

Use for a reported defect. Reproduce first, trace the root cause, add the smallest regression proof available, fix, verify, and review. Promote to the governed feature path if the fix changes a public contract, schema, security boundary, scope, or architecture.

### Refactoring

Use when structure changes but behavior must not. Pin the behavior, define the target shape, subtract dead weight, migrate callers, verify equivalence, and promote to feature when behavior changes.

### Performance issue

Use for a single measured performance problem. Establish a realistic baseline, profile, form a mechanism-based hypothesis, change one thing, and measure before and after.

### Hillclimb

Use for sustained improvement against a metric. Freeze the measurement harness, log each hypothesis, keep or revert each change, preserve the regression gate, and stop only on an explicit predicate or a documented plateau.

### Architecture

Use `architect` when data shape, ownership, dependency direction, public surface, bounded context, or security boundary is unsettled. `architect` grounds, sketches, uses `arena` for genuinely contested alternatives, and proceeds without an automatic checkpoint.

### Large or multi-session work

Use `wayfinder` when the route is too large or uncertain for one session. Use `handoff` and `show-me-your-work` when the task must survive a session boundary or unattended period.

### Review and delivery

Use `code-review` for fixed-point review. Use the repository's GitHub and `commit` skills for PR and commit operations. Do not import Cursor-specific Graphite, `/loop`, or `poteto-agent` behavior.

## Promotion rules

Promote a local capability to the governed dev-cycle path when the work changes:

- product behavior;
- scope;
- a public API or trait;
- a schema or persisted format;
- a bounded context;
- ownership or dependency direction;
- a security or trust boundary;
- a major compatibility decision;
- a durable architectural decision;
- a contract future agents must know.

Do not promote solely because the task uses a prototype, benchmark, investigation, or local reversible edit.

## Delegation

Use `delegate_task` with explicit context, scope, fences, and completion criteria.

- Use parallel workers for independent research or genuinely independent artifacts.
- Use `arena` for competing designs, not for mechanical edits.
- Use explicit git worktrees when parallel workers write to the same repository.
- Keep the parent responsible for synthesis, external effects, and verification.
- Trust artifacts, not delegate summaries.

## Completion

Before declaring the task complete:

- all applicable modes and capabilities have reached their completion criteria;
- all user-owned decisions are settled;
- the required spec, ticket, implementation, or diagnosis exists;
- the real artifact was exercised or inspected;
- the relevant tests, checks, or measurements passed;
- every changed file is accounted for;
- the final report names principles that changed decisions;
- unresolved risks and next steps are explicit.

## Direct skill invocation

The phase skills remain directly invocable. When invoked directly, each skill owns its own prerequisites and must load `architect`, `coding-standards`, `testing`, `writing-for-agents`, or other dependencies when its procedure requires them. The router does not replace these pointers.
