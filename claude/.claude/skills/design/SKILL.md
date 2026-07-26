---
name: design
description: >
  Architecture and system design guidelines. Invoke when user asks to add a feature, create a module or class,
  design an API, refactor structure, mentions architecture, layers, hexagonal/ports-and-adapters, bounded
  contexts, shared state, domain errors, observability, or threat modeling.
---

## Structure: Workspace, Hexagonal / Ports & Adapters

Only choice: one package/module per architectural role, multi-package workspace — dependency direction enforced by toolchain, not convention. Language-specific layout (crate table, manifest wiring, static-vs-dynamic dispatch tradeoffs) lives in per-language reference (e.g. `reference/rust_structure.md`).

## Internal Layering

1. **Handler (adapter layer):** Input/HTTP. Parse + validate. Maps wire types ↔ domain command/result types.
2. **Service (domain layer):** Business logic. Orchestrate. Written against its own ports, not concrete adapters.
3. **Repository/adapter (infra layer):** Data access / external system. Implements a domain-layer port.
4. **Middleware (adapter layer):** Observability + cross-cutting.

## Shared State & Error Handling

* Shared app state generic over same port types as services it holds. Never names concrete infra type; only composition root does.
* No single error type crosses every layer. Domain layer owns one error type, zero HTTP/infra concepts in it. Adapter layer wraps it in own error type for framework's response-conversion mechanism — see Cross-Boundary Error Handling below.

## Bounded Contexts

**One domain package per bounded context**, not one shared domain package for everything. Second feature = parallel domain package (+ own infra adapters, + its slice of HTTP layer), never module bolted onto first context's package.

**Shared kernel, kept minimal.** If context B needs reference something owned by context A (user ID, order ID), don't have B depend on A's whole package — pull identifier into tiny shared-kernel package (just identifier/value type, no business rules) both depend on. Moment that package grows business rule, it's not shared kernel anymore — move rule into whichever context owns it.

## Cross-Boundary Error Handling

Domain layer owns one error type, zero HTTP/infra concepts. Infra layer method bodies use internal untyped/generic error representation so every underlying error (DB driver, cache client, whatever) converts free through language's normal error-propagation mechanism, then exactly **one** explicit conversion into domain error per public method at boundary (not per call site — difference between one-time tax and recurring one). HTTP/adapter layer wraps domain error in *own* error type for framework's response conversion — package/module boundaries typically mean can't implement foreign interface for foreign type from third package, so wrapper structurally required, not optional ceremony. See language-specific reference for exact mechanism.

## Boundary DTO Rule

Once entities/services live in domain package, can't carry framework-specific interface implementations — no ORM row-mapping, no HTTP response/request-parsing interfaces, no schema-generation annotations tied to specific web framework. Expect: shadow persistence type + mapping function in infra package for anything that used to bind domain entity directly to row/document shape; plain result/command types in domain package, mapped to/from framework-flavored wire types in HTTP package. Budget for this up front when scoping bounded context — not optional scope creep, language's own visibility/interface rules force it.

## Cross-Cutting Concerns Aren't Bounded-Context Business

Health checks, audit logging, generic observability — don't let ride on business port (repository interface gaining `check_db`-style method wrong: dependency reachability has no business rule attached). Give own small interface/package. If abstraction fully generic (no project-specific logic), belongs in shared library project already depends on, not reinvented per-project — check whether existing internal library already owns adjacent responsibility before writing new one-off version.

## Composition Root

Only entry-point package names concrete adapter types and wires them together. HTTP/adapter layer's shared state stays generic over same port types as service — should never need name concrete infra type, else concrete dependency leaked past boundary just built.

## Repository Structure

* No monolithic files. Split by focus.
* Always include private `queries` module. Externalize SQL to sibling `sql/` dir, one `.sql` file per query, loaded via language's "include file as string" mechanism.
* Check `utils` before writing inline. Consult language-specific reference.
* Use interfaces/traits to decouple from caller.

## Observability (Mandatory)

* Logging, metrics, tracing mandatory day 0.
* Via middleware layer only.
* Missing middleware/metrics? REMIND user. **DO NOT show examples** unless asked.

## Threat Modeling (Mandatory for New Features)

* Identify trust boundaries first.
* Assets? Actors? Attack surfaces?
* STRIDE: Spoofing, Tampering, Repudiation, Information Disclosure, DoS, Elevation of Privilege.
* Network/privilege boundary? Security review mandatory before impl.

## References

- `reference/rust_structure.md` — Rust: Cargo workspace / hexagonal crate layout, generic-vs-`dyn Trait` dispatch rule
- `reference/rust-rs-repository-utils.md` — Rust: `rs-repository-utils` exports, integration rules, Prometheus wiring, `HealthIndicator` pattern
- `reference/rust-string-types.md` — Rust: string type governance (`&'static str` / `Box<str>` / `Cow` / `Arc<str>`), error-type security tier pattern, `Box<str>` PartialEq in tests
- `reference/rust-sql-queries.md` — Rust: externalizing SQL to `.sql` files, naming, `include_str!` wiring
