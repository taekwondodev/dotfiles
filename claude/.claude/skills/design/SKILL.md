---
name: design
description: >
  Architecture and system design guidelines. Enforces internal layering (Handler/Service/Repository/Middleware),
  AppState/AppError patterns, repository structure, mandatory observability, and threat modeling.
  Invoke when designing a new feature, creating a new module, or doing structural refactoring.
---

## Internal Layering

1. **Handler:** HTTP/Input. Parse + validate.
2. **Service:** Business logic. Orchestrate.
3. **Repository:** Data access. Abstract persistence.
4. **Middleware:** Observability + cross-cutting.

## Shared State & Error Handling

* `AppState` own file.
* `AppError` — single error type, own file.

## Repository Structure

* No monolithic files. Split by focus.
* Always include private `queries` module.
* Check `utils` before writing inline. Consult language-specific reference.
* Use traits to decouple from caller.

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

- `reference/rust_structure.md` — Rust project layout
- `reference/rust-rs-repository-utils.md` — `rs-repository-utils` exports, integration rules, Prometheus wiring
- `reference/rust-string-types.md` — String type governance (`&'static str` / `Box<str>` / `Cow` / `Arc<str>`), `AppError` security tier pattern, `Box<str>` PartialEq in tests
