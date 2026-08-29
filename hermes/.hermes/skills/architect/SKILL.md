---
name: architect
description: Sketch and compare architecture before implementing cross-boundary code.
---

# Architect

Design before implementing. Use this skill when a change can lock in the wrong data shape, public interface, module boundary, ownership model, dependency direction, or security boundary. The skill produces a grounded sketch, compares viable structures, and keeps implementation aligned with the chosen shape.

This skill does not make hexagonal or ports-and-adapters mandatory. Choose the smallest architecture that protects the real boundaries and invariants of the system.

## When to Use

Use when:

- code crosses a module, package, crate, service, or bounded-context boundary;
- a public function, trait, API, schema, or persisted format changes;
- a new module or responsibility needs an owner;
- the data shape or lifecycle model is unclear;
- multiple architecture shapes are plausible;
- the existing structure is causing repeated implementation friction;
- a security boundary, trust boundary, or privileged operation changes;
- the user explicitly asks to architect, sketch, compare, or redesign a change.

Do not use for a mechanical local edit whose ownership, data shape, and boundaries are already clear. Do not use this skill to ask the user for facts that repository inspection, tests, prototypes, or profiling can establish.

## Applicable Principles

Load and apply the canonical principle skills when their triggers fire:

- `principle-foundational-thinking` before choosing types, data structures, or scaffold sequence.
- `principle-model-the-domain` when state, branching, or repeated shape assumptions need a structure.
- `principle-boundary-discipline` when validation, errors, adapters, or framework boundaries are involved.
- `principle-type-system-discipline` when designing types or signatures.
- `principle-exhaust-the-design-space` when the architecture is novel or contested.
- `principle-redesign-from-first-principles` when integrating a requirement into an existing design.
- `principle-minimize-reader-load` when comparing interfaces and indirection.
- `principle-prove-it-works` when checking the resulting implementation.
- `principle-fix-root-causes` when implementation friction suggests the sketch is wrong.
- `principle-separate-before-serializing-shared-state` when concurrent actors may write shared state.
- `principle-make-operations-idempotent` when lifecycle steps can be retried or restarted.

A principle must change a decision or verification step. Do not list a principle without recording the choice it influenced.

## Procedure

### 1. Ground

Build a traced model of the existing system before proposing structure.

- Use `search_files` and `read_file` to locate the entry point, callers, callees, types, data flow, and current boundaries.
- Use `how` for a subsystem walkthrough when the flow is not already clear.
- Use `why` when existing rationale or an ADR may constrain the choice.
- Read the relevant domain context, ADRs, and design documents.
- Identify current ownership, dependency direction, error conversion, validation boundary, observability, and security assumptions.

Completion criterion: the caller-to-effect path, affected types, current owner, and constraints are written down without relying on file names alone.

### 2. Threat model

Run threat modeling before selecting a structure whenever the change touches authentication, authorization, secrets, personal data, network boundaries, privileged actions, persisted security state, or another trust boundary.

Record:

- assets that require protection;
- actors and their capabilities;
- trust boundaries crossed;
- attack surfaces introduced or changed;
- relevant STRIDE concerns: spoofing, tampering, repudiation, information disclosure, denial of service, and elevation of privilege;
- mitigations and residual risks;
- which layer owns each mitigation.

Do not turn threat modeling into a checklist detached from the design. Use each material finding to change a boundary, type, permission, validation rule, error policy, logging rule, or test decision.

Completion criterion: every changed trust boundary has named assets, actors, attack surfaces, relevant threats, and an owner for each mitigation, or a recorded reason why threat modeling is not relevant.

### 3. Sketch

Write the caller's intended usage first. Derive the design from that usage.

The sketch must include the smallest useful set of:

- commands, queries, or entry points;
- data shapes and lifecycle states;
- domain types and invalid states they prevent;
- public function or trait signatures;
- module or package map;
- ownership of behavior and invariants;
- dependency direction;
- error boundaries and conversion points;
- validation and serialization boundaries;
- observability responsibilities;
- security controls from the threat model.

Use `not implemented` bodies or pseudocode where that makes the shape precise. A sketch is not a working implementation and must not hide an unresolved decision behind vague prose.

Completion criterion: a reviewer can identify the caller-facing contract, the owning module, the important types, and every cross-boundary dependency from the sketch.

### 4. Arena

Load `arena` when the design is novel, contested, or likely to affect several boundaries. Pass it the grounded model, requirements, threat model, caller usage, requested output shape, and explicit write fences. `arena` owns candidate dispatch, isolation, and synthesis; this skill owns the decision to invoke it and consumes its comparison.

Completion criterion: the candidates, their assumptions, and their tradeoffs are available for comparison, or the sketch records why a second candidate would add no information for a genuinely local and settled structure.

### 5. Compare

Compare viable candidates against:

- domain fit and invalid-state prevention;
- public surface and interface depth;
- ownership and dependency direction;
- reader load and hidden state;
- error and validation boundaries;
- security and threat mitigations;
- observability;
- operational and migration risk;
- implementation complexity;
- reversibility and idempotence.

Prefer the smallest structure that protects the real boundaries. Do not select an abstraction because it is fashionable or because it creates more layers.

Record:

- the selected candidate;
- rejected candidates;
- the decisive tradeoffs;
- the principles that changed the decision;
- open risks that implementation must verify.

Completion criterion: one candidate is selected with a concrete rationale, and rejected candidates have a specific reason rather than an aesthetic dismissal.

### 6. Implement against the sketch

When this skill is invoked as part of implementation, use the selected sketch as the contract.

- Start from the caller-facing shape.
- Keep the implementation inside the selected ownership and dependency boundaries.
- Surface a deviation instead of silently bolting on a new parameter, wrapper, optional field, or compatibility path.
- Apply `principle-migrate-callers-then-delete-legacy-apis` when an internal API changes.
- Use explicit Hermes `delegate_task` contexts for delegated work.
- Inspect delegated artifacts directly with `read_file`, `search_files`, git diff, and the matching verification command.

Completion criterion: every implementation deviation is either resolved by revising the sketch or recorded as an accepted requirement or constraint.

### 7. Scrap and redesign

If implementation produces repeated friction, do not stack workarounds on the sketch.

Signals include:

- repeated special-case branches;
- multiple callers learning internal abstraction rules;
- types requiring casts or escape hatches;
- the same workaround appearing in unrelated modules;
- a lock or serializer added because ownership was never separated;
- repeated deviations from the same part of the sketch.

When the signal is structural:

1. Re-run `how` over what was built.
2. Update the constraints with the implementation evidence.
3. Apply `principle-redesign-from-first-principles`.
4. Subtract dead weight before adding the new shape.
5. Return to Sketch and Arena.

Completion criterion: the replacement sketch accounts for the repeated friction and is smaller or clearer in the affected area before implementation resumes.

## Checkpoint

No automatic checkpoint is part of this skill. The normal behavior is to complete the synthesis and continue unless the user explicitly asks to stop.

Recognized requests include:

- `architect with checkpoint`;
- `stop after the sketch`;
- `show me the candidates before implementing`.

When explicitly requested, present the sketch, candidates, comparison, threat model, and selected design, then wait for the user's decision.

## Architecture Options

Evaluate architecture from the problem rather than assuming one pattern.

Possible references include:

- `references/hexagonal.md` for ports-and-adapters;
- `references/layered.md` for layered structures;
- `references/modular-monolith.md` for module boundaries without unnecessary deployment boundaries;
- `references/rust-structure.md` for repository-specific Rust workspace structure;
- `references/rust-string-types.md` for Rust domain-string modeling;
- `references/rust-sql-queries.md` for SQL query boundaries in Rust;
- `references/rust-rs-repository-utils.md` for repository utilities in Rust.

A reference informs a decision. It does not override the grounded system model or force a pattern that protects no real boundary.

## Hermes Adaptation

Use Hermes mechanisms:

- `read_file` and `search_files` for grounding;
- `delegate_task` for candidates and independent exploration;
- `todo` for visible phases;
- `clarify` only for explicit user-owned decisions or an explicitly requested checkpoint;
- explicit git worktrees when parallel workers write to the repository;
- `terminal` for builds, tests, profiling, and git verification.

Do not use Cursor-specific `Task`, `AskQuestion`, `poteto-agent`, Graphite, `/loop`, or control skills.

## Verification

Before declaring the architecture useful:

- the caller-facing sketch exists;
- the selected candidate and rejected alternatives are recorded;
- threat modeling is complete when relevant;
- every cross-boundary dependency has an owner;
- the implementation or prototype follows the selected shape;
- deviations are explained or the sketch is redesigned;
- the relevant build, tests, profiling, or runtime check has been run;
- the final report names the principles that changed decisions.
