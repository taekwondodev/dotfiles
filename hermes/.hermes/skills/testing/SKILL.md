---
name: testing
description: >
  Testing strategy guidelines. Invoke when user asks to write tests, add a test suite, mentions
  unit tests, integration tests, coverage, TDD, test file structure, or which layer to test.
---

## Scope & Exclusions

* **STRICTLY NO** unit tests for **Handlers** (Input/HTTP layer).
* **STRICTLY NO** unit tests for **Repositories** (Data Access layer).
* **Focus:** Unit tests only on **Service layer** (Business Logic) and **Domain Types** (TyDD validation).

## File Structure

* No inline tests at file bottom.
* `tests/` dir at same level as module.
* Name test files consistently with module (e.g., `request_test` for `request`).
* Declare test modules conditionally so they are excluded from prod builds.

## Coverage

* Test behavior + domain invariants, not implementation details.
* Security tests: **OWASP Testing Guide**.

## Test quality and anti-patterns

* **Implementation-coupled**: mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface). Tell: the test breaks on refactor with no behavior change.
* **Tautological**: the assertion recomputes the expected value the way the code does, so it passes by construction. Expected values come from an independent source of truth, such as a known-good literal, a worked example, or the spec's acceptance criteria. Never derive them using the same reasoning that produced the implementation.
* **Self-graded**: the same agent invocation that wrote the implementation also invented the test's expected values from scratch. It shares the implementation's blind spots by construction. Derive expected values from the spec/ticket instead, or have a separate `/code-review` pass judge the tests independently.
