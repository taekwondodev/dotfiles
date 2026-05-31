---
name: testing
description: >
  Testing strategy guidelines. Defines scope, exclusions, file structure, and coverage rules.
  Invoke when writing tests or setting up a test suite.
---

## Scope & Exclusions

* **STRICTLY NO** unit tests for **Handlers** (Input/HTTP layer).
* **STRICTLY NO** unit tests for **Repositories** (Data Access layer).
* **Focus:** Unit tests only on **Service layer** (Business Logic) and **Domain Types** (TyDD validation).

## File Structure

* No inline tests at bottom of source file.
* Create `tests/` dir at same level as module being tested.
* Name test files consistently with module (e.g., `request_test` for `request`).
* Declare test modules conditionally — excluded from production builds.

## Coverage

* Test behavior + domain invariants, not implementation details.
* Security tests follow **OWASP Testing Guide** as reference standard.
