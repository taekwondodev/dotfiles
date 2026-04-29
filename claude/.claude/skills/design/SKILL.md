---
name: design
description: >
  Architecture and system design guidelines. Enforces internal layering (Handler/Service/Repository/Middleware),
  AppState/AppError patterns, repository structure, mandatory observability, and threat modeling.
  Invoke when designing a new feature, creating a new module, or doing structural refactoring.
---

## Internal Layering

Strictly adhere to separation of concerns within each module:

1. **Handler:** HTTP/Input layer. Parses and validates incoming requests.
2. **Service:** Business logic layer. Orchestrates domain operations.
3. **Repository:** Data access layer. Abstracts persistence.
4. **Middleware:** Observability and cross-cutting concerns.

## Shared State & Error Handling

* Use a dedicated `AppState` structure for shared application state, defined in its own file.
* Use a centralized `AppError` type for global error handling. It must be the **only** error type returned by the server, defined in its own file.

## Repository Structure

* **Split Files:** Strictly avoid monolithic repository files. Split implementations into multiple focused files.
* **Queries Module:** Always include a private `queries` module within the repository.
* **Utils Reminder:** If a `utils` module for data access operations is missing, REMIND the user to create it. **DO NOT show examples** unless explicitly asked.
* **Pattern:** Use interfaces/traits/abstractions to decouple implementation from the caller.

## Observability (Mandatory)

* **Day 0 Implementation:** Structured logging, metrics collection, and tracing are mandatory from the start, not optional.
* **Implementation:** Must be implemented via the middleware layer.
* **Check:** If middleware/metrics are missing, REMIND the user immediately. **DO NOT show examples** unless explicitly asked.

## Threat Modeling (Mandatory for New Features)

* Before designing a new feature, identify its trust boundaries.
* Ask: What are the assets? Who are the actors? What are the attack surfaces?
* Use STRIDE as a mental checklist (Spoofing, Tampering, Repudiation, Information Disclosure, DoS, Elevation of Privilege).
* If a trust boundary crosses the network or a privilege level, a security review of the design is mandatory before implementation.
