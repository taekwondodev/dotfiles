# Modular Monolith

A modular monolith keeps one deployable process while enforcing strong internal module boundaries.

## Use When

Use it when deployment independence is not yet valuable but ownership, dependency direction, and bounded contexts must remain explicit.

## Costs

A module boundary that is enforced only by convention can decay. The structure needs package visibility, dependency checks, or other executable constraints where the language and build system allow them.

## Decision Questions

- Which responsibilities and invariants belong together?
- Which dependencies are allowed between modules?
- What shared kernel is genuinely small enough to share?
- Would a separate deployment solve a real problem now, or only add operations?

A modular monolith can be combined with layered or hexagonal internals when each choice protects a distinct boundary.
