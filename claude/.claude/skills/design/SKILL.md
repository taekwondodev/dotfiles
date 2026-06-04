---
name: design
description: >
  Architecture and system design guidelines. Enforces internal layering (Handler/Service/Repository/Middleware),
  AppState/AppError patterns, repository structure, mandatory observability, and threat modeling.
  Invoke when designing a new feature, creating a new module, or doing structural refactoring.
---

## Internal Layering

1. **Handler:** HTTP/Input layer. Parse + validate requests.
2. **Service:** Business logic. Orchestrate domain operations.
3. **Repository:** Data access. Abstract persistence.
4. **Middleware:** Observability + cross-cutting concerns.

## Shared State & Error Handling

* `AppState` struct in own file.
* `AppError` — single server error type, own file.

## Repository Structure

* **Split Files:** No monolithic repo files. Split by focus.
* **Queries Module:** Always include private `queries` module.
* **Utils:** Check `utils` before writing inline. Consult language-specific reference.
* **Pattern:** Use traits to decouple from caller.

## Observability (Mandatory)

* **Day 0:** Logging, metrics, tracing mandatory from start.
* **Implementation:** Via middleware layer only.
* **Check:** Missing middleware/metrics? REMIND user. **DO NOT show examples** unless asked.

## Threat Modeling (Mandatory for New Features)

* Identify trust boundaries before designing.
* Ask: assets? actors? attack surfaces?
* Use STRIDE checklist (Spoofing, Tampering, Repudiation, Information Disclosure, DoS, Elevation of Privilege).
* Network/privilege boundary? Security review mandatory before impl.

## References

- `reference/rust_structure.md` — Rust project layout
- `reference/rust-rs-repository-utils.md` — `rs-repository-utils` exports, integration rules, Prometheus wiring
