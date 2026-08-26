# Dev-Cycle and pstack Integration Plan

> **For Hermes:** This document records the agreed design before implementation. Do not modify skills until the user explicitly starts the implementation phase.

**Goal:** Evolve the repository's development skills around a single sticky `dev-cycle` entrypoint, incorporating the useful parts of pstack while preserving the repository's governance, source-of-truth, and human checkpoints.

**Architecture:** `dev-cycle` becomes the primary router and coordinator. Existing phase skills remain directly invocable and own their procedures. pstack playbooks become capabilities inside the appropriate existing skills or disclosed references. The 21 pstack principles become canonical reusable skills, with a deliberate short index in `dev-cycle` following pstack's design.

**Environment:** Hermes Agent on macOS. The source repository is `/Users/taekwondodev/dotfiles`. The workflow uses Hermes tools, GitHub Issues, `delegate_task`, `clarify`, `todo`, and existing repository skills. Cursor-specific concepts must be adapted rather than copied.

---

## Agreed constraints

### One source of truth

Each rule has one canonical owner.

- `unslop` exists only in `writing-for-agents`.
- The no-comments rule exists only in `coding-standards`.
- Full principle definitions have one canonical location each.
- Other skills may name or point to a principle, but must not create weaker competing formulations.
- pstack's short inline principle index in `dev-cycle` is an intentional, narrow exception. The complete principle remains canonical in its own principle skill.
- `menu` derives its catalog from real skill metadata and descriptions. It does not maintain a manual duplicate catalog.

### Entry point and persistence

- `dev-cycle` is the primary and normal entrypoint. No separate `dev-mode` skill is created.
- All skills remain directly invocable for overrides and focused work.
- Direct invocation does not authorize bypassing another skill's contracts, human gates, or verification requirements.
- `dev-cycle` is sticky during the current task.
- `continue` resumes the current task and playbook.
- `new task` resets routing and starts a new task.
- Hermes `/new` remains the actual fresh-session command.

### Human checkpoints

The agent may proceed autonomously with facts, investigation, prototypes, benchmarks, tests, and reversible preparation.

A checkpoint is mandatory in the governed `dev-cycle` path before decisions about:

- product behavior;
- scope;
- architecture;
- bounded contexts;
- ownership or dependency direction;
- public APIs or traits;
- schemas or persisted formats;
- security boundaries;
- major compatibility decisions.

The standalone `architect` skill follows pstack `architect` and does not insert an automatic checkpoint, including when `dev-cycle` activates it. A checkpoint can be requested explicitly. Product and scope checkpoints remain owned by `dev-cycle`; activating `architect` alone does not create an architecture checkpoint.

### Routing

`dev-cycle` selects one primary mode and may activate secondary capabilities.

- Factual uncertainty routes to investigation.
- Technical uncertainty routes to `how` or prototype.
- Architectural uncertainty routes to `architect`, possibly with `arena`.
- Product or scope uncertainty routes to grilling and a human checkpoint.
- A task is promoted when it changes a contract, boundary, scope, or architectural decision.
- When classification is uncertain, choose the least-commitment path that can reduce uncertainty.

### Direct skill categories

- Primary entrypoint: `dev-cycle`.
- Phase skills: `grilling`, `to-spec`, `to-tickets`, `implement`, `code-review`, `wayfinder`, `handoff`.
- Specialist skills: `architect`, `investigation`, `prototype`, `runtime-forensics`, `trace-forensics`, `blast-radius`, `interrogate`, and other useful focused capabilities.
- Principle skills: `principle-*`, directly invocable but normally used as support.
- `menu`: read-only catalog and discovery skill.

---

## Target workflow

```text
dev-cycle
  -> classify the task
  -> initialize todo and applicable principles
  -> separate facts, hypotheses, and decisions
  -> run investigation, how, prototype, profiling, or forensics as needed
  -> grilling and decision tree
  -> human checkpoint when product, scope, architecture, or contract is involved
  -> to-spec
  -> to-tickets when multiple slices are needed
  -> implement
  -> code-review
  -> verified completion or handoff
```

Example:

```text
dev-cycle perché X continua a funzionare?
  -> grilling recognizes a factual question
  -> investigation gathers evidence before asking the user
  -> grilling asks only unresolved decision questions
```

Feature, refactoring, bug-fix, performance, and hillclimb are modes within `dev-cycle`, not competing workflows.

References from phase skills to the former `design` skill must not be removed merely because `dev-cycle` also routes to `architect`. They must be updated to `architect` when they express a real procedural dependency. The router chooses when to activate `architect`; each directly invocable phase skill states when it must load or apply `architect` so direct invocation remains correct. No skill copies `architect`'s rules.

---

## Pstack principles

Import all 21 principles using pstack's formulations as the authoritative baseline. Replace weaker or partial formulations in existing skills.

1. `principle-laziness-protocol`
2. `principle-foundational-thinking`
3. `principle-redesign-from-first-principles`
4. `principle-subtract-before-you-add`
5. `principle-minimize-reader-load`
6. `principle-outcome-oriented-execution`
7. `principle-experience-first`
8. `principle-exhaust-the-design-space`
9. `principle-build-the-lever`
10. `principle-model-the-domain`
11. `principle-boundary-discipline`
12. `principle-type-system-discipline`
13. `principle-make-operations-idempotent`
14. `principle-migrate-callers-then-delete-legacy-apis`
15. `principle-separate-before-serializing-shared-state`
16. `principle-prove-it-works`
17. `principle-fix-root-causes`
18. `principle-sequence-verifiable-units`
19. `principle-guard-the-context-window`
20. `principle-never-block-on-the-human`
21. `principle-encode-lessons-in-structure`

The `never-block-on-the-human` principle must be adapted for this workflow:

> Do not block the user for observable facts, reversible operations, or preparation. Stop for product, scope, architecture, contract, security, and other decisions that require human ownership.

Each rewritten skill must state which principles it applies and what concrete decision or behavior each principle changes. Merely listing a principle is insufficient.

---

## `architect` replacement for `design`

Rename the current `design` skill to `architect` and rewrite it as the repository's Hermes adaptation of pstack `architect`.

It must:

1. Ground the existing system with `how`.
2. Consult `why` when existing rationale matters.
3. Define caller usage before implementation details.
4. Sketch data shapes, types, signatures, module boundaries, ownership, and dependency direction before code.
5. Use `arena` for genuinely novel or contested architecture, requiring at least two structurally distinct candidates.
6. Compare candidates using boundaries, reader load, coupling, invalid states, security, observability, and implementation cost.
7. Do not insert an automatic approval checkpoint, including when invoked through `dev-cycle`. Support an explicit checkpoint request when the user asks to review the sketch before implementation.
8. Treat hexagonal / ports-and-adapters as one reference option, not the universal answer.
9. Add threat modeling to the architecture pass, covering assets, actors, trust boundaries, attack surfaces, and STRIDE where relevant.
10. Return to grounding and redesign from first principles when implementation produces repeated structural friction.

The sketch is a phase of `architect`, not a separate skill.

Potential reference structure:

```text
architect/
  SKILL.md
  references/
    hexagonal.md
    layered.md
    modular-monolith.md
    rust-structure.md
```

Existing Rust-specific references should be preserved and updated only where their assumptions depend on the old skill name or on hexagonal being mandatory.

---

## Capability integration map

### Into `dev-cycle`

Integrate the pstack mode behavior and these internal modes:

- `feature`: the normal new-behavior path, preserving grilling, checkpoint, spec, tickets, implementation, and review.
- `refactoring`: behavior-preserving contract, characterization/equivalence proof, target shape, subtraction, caller migration, and verification.
- `bug-fix`: reproduction, root cause, regression proof, fix, verification, and review.
- `perf-issue`: baseline, workload, profiling, hypothesis, change, and before/after measurement.
- `hillclimb`: frozen measurement harness, one hypothesis per iteration, keep/revert, stop predicate, and decision log.

### Into `grilling`

Integrate or activate:

- `how` for code and ownership walkthroughs;
- `why` for rationale and history;
- `investigation` for factual questions before user questions;
- `prototype` for empirical technical forks;
- `runtime-forensics` for live-process diagnosis;
- `trace-forensics` for already captured artifacts;
- bug reproduction;
- promotion to `architect` or the governed dev-cycle path when needed.

### Into `architect`

Integrate:

- pstack `architect` phases;
- sketch artifacts;
- `arena` for competing designs;
- `prototype` for feasibility;
- `how` and `why` grounding;
- `model-the-domain`;
- `redesign-from-first-principles`;
- threat modeling covering assets, actors, trust boundaries, attack surfaces, and STRIDE where relevant.

### Into `to-spec`

Integrate:

- architecture findings and selected sketch;
- `how` and `why` evidence;
- `blast-radius` findings;
- `experience-first` scope reasoning;
- `outcome-oriented-execution`;
- explicit testing decisions;
- evidence from investigation or prototype when it changed a decision.

### Into `to-tickets`

Integrate:

- `sequence-verifiable-units`;
- `build-the-lever`;
- `blast-radius`;
- `migrate-callers-then-delete-legacy-apis`;
- refactoring expand-contract sequencing;
- hillclimb iteration boundaries when work spans sessions.

### Into `implement`

Integrate:

- architecture sketch handoff;
- feature, bug-fix, refactoring, performance, and hillclimb modes;
- `build-the-lever`;
- `prove-it-works`;
- `sequence-verifiable-units`;
- `blast-radius`;
- applicable type, boundary, domain, idempotence, and migration principles.

Do not integrate TDD.

### Into `code-review`

Integrate:

- existing separate `Standards` and `Spec` axes;
- `interrogate` as an adversarial challenge pass;
- `blast-radius`;
- refactoring contract verification;
- no-comments enforcement through `coding-standards` only.

### Into `wayfinder`

Integrate:

- pstack `figure-it-out` behavior;
- `show-me-your-work` decision trails;
- `swarm` for independent research or slices;
- hillclimb for multi-session measurement work;
- session pickup and pause semantics.

### Into `handoff`

Integrate:

- `recall`;
- `session-pickup`;
- `pause-safely`;
- `show-me-your-work`;
- current task, playbook, decisions, evidence, git state, tests, and next completion criterion.

### Into `coding-standards`

Strengthen the existing no-comments rule. This remains the only source of truth for the rule.

- Comments describe non-obvious why only.
- Comments must not describe what code does.
- The rule applies to production code, tests, scripts, migrations, and configuration.
- `code-review` checks the rule but does not redefine it.

### Into `writing-for-agents`

Keep `unslop` here and nowhere else. Keep this skill as the only source of truth for agent-facing writing, including skills, specs, tickets, handoffs, and review reports.

### `menu`

Create one separate read-only skill outside `dev-cycle`.

Supported forms:

```text
menu
menu architect
menu per fare performance profiling
```

Behavior:

- derive the catalog from actual skill metadata and descriptions;
- show all skills by default;
- distinguish primary entrypoints, directly invocable skills, specialist capabilities, and principle skills;
- rank free-form intent searches by relevance;
- explain each result's role and relationship to `dev-cycle`;
- never start a workflow or modify state;
- never maintain a manually duplicated catalog.

---

## Hermes adaptations

Do not copy Cursor-specific implementation details.

| pstack / Cursor concept | Hermes adaptation |
|---|---|
| `Task` / `subagent_type` | `delegate_task` with explicit context and `leaf` or `orchestrator` role |
| `AskQuestion` | `clarify` with frontier questions and concrete choices |
| `mode: true` | sticky `dev-cycle` behavior, `continue`, and `new task` semantics |
| Cursor worktree behavior | explicit git worktrees for parallel writes |
| `poteto-agent` | Hermes delegated workers with explicit contracts |
| model per Cursor Task | Hermes delegation configuration and available model routing, without inventing unsupported per-task parameters |
| `/loop` | Hermes `cronjob`, `process`, background tools, or ordinary continuation when appropriate |
| Graphite shipping | existing git, GitHub, commit, and PR skills |
| Cursor control skills | Hermes browser, terminal, desktop, and verification tools |
| Cursor plugin metadata | Hermes skill frontmatter and local skill conventions |

The parent agent owns aggregation and verification. Delegated self-reports are not proof.

The pstack pattern is also intentionally dual-layered: `poteto-mode` routes to `architect`, while feature and other playbooks refer to `architect` when their own procedure requires it. Hermes will preserve this behavior with `dev-cycle` as the router and explicit `architect` pointers in phase skills.

---

## Evaluation plan

Before declaring the rewrite successful, evaluate the old and new behavior against the same scenarios:

- read-only code question;
- factual bug investigation;
- local bug fix;
- bug fix requiring a public API change;
- simple feature;
- multi-layer feature;
- behavior-preserving refactoring;
- one-off performance issue;
- iterative hillclimb;
- live runtime symptom;
- existing trace artifact;
- novel architecture decision;
- large uncertain effort;
- explanation request;
- rationale request;
- `menu` catalog request.

For every scenario verify:

- chosen primary mode;
- secondary capabilities activated;
- applicable principles named;
- factual investigation happens before avoidable questions;
- correct human checkpoint behavior;
- no accidental TDD behavior;
- `unslop` is sourced only from `writing-for-agents`;
- no-comments is sourced only from `coding-standards`;
- architecture decisions are not forced into hexagonal;
- review preserves separate Standards and Spec axes;
- final claims are grounded in real verification.

---

## Likely files to modify

- `hermes/.hermes/skills/dev-cycle/SKILL.md`
- `hermes/.hermes/skills/grilling/SKILL.md`
- `hermes/.hermes/skills/to-spec/SKILL.md`
- `hermes/.hermes/skills/to-tickets/SKILL.md`
- `hermes/.hermes/skills/implement/SKILL.md`
- `hermes/.hermes/skills/code-review/SKILL.md`
- `hermes/.hermes/skills/wayfinder/SKILL.md`
- `hermes/.hermes/skills/handoff/SKILL.md`
- `hermes/.hermes/skills/coding-standards/SKILL.md`
- `hermes/.hermes/skills/writing-for-agents/SKILL.md`, only if a source-of-truth adjustment is required
- `hermes/.hermes/skills/architect/SKILL.md`, replacing the former `design` skill
- new `principle-*/SKILL.md` files under `hermes/.hermes/skills/`
- new `hermes/.hermes/skills/menu/SKILL.md`
- architecture references where needed

- project-local tests or eval fixtures, if the current skill test infrastructure supports them

Preserve unrelated existing modifications. Do not touch profile configuration unless a later, explicit decision requires it.

---

## Implementation order

1. Re-read this plan and inspect every affected skill.
2. Create the canonical principle skills and verify their exact pstack formulations.
3. Rewrite `coding-standards` and `writing-for-agents` source-of-truth boundaries first.
4. Rewrite and rename `design` as `architect`, including sketch, arena, alternatives, and Hermes delegation.
5. Rewrite `grilling` to investigate facts before asking questions.
6. Rewrite `dev-cycle` as the sticky router and coordinator.
7. Update `to-spec`, `to-tickets`, `implement`, `code-review`, `wayfinder`, and `handoff` with their owned capabilities.
8. Add `menu` as the read-only catalog.
9. Update all skill references from `design` to `architect`; do not add a second bundle layer.
10. Build and run the evaluation matrix.
11. Re-read all source-of-truth owners and search for duplicate rules.
12. Review the diff and preserve unrelated changes.

No implementation, commit, push, or external issue modification is part of this plan document itself.

---

## Open implementation checks

These are implementation checks, not unresolved strategic decisions:

- confirm Hermes's skill loader behavior for direct invocation and sticky context;
- confirm the best local structure for principle references while preserving discoverability;
- confirm how `menu` can query skill metadata and distinguish capability levels;
- confirm whether existing tests can exercise skill routing without live network calls;
- confirm all current `design` references before renaming;
- confirm parallel architecture candidates use safe worktrees when they write artifacts.
