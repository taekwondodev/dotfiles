---
name: testing
description: >
  Testing strategy guidelines. Invoke when user asks to write tests, add a test suite, mentions
  unit tests, integration tests, coverage, test file structure, or which layer to test.
---

## Scope & Exclusions

* **STRICTLY NO** unit tests for **Handlers** (Input/HTTP layer).
* **STRICTLY NO** unit tests for **Repositories** (Data Access layer).
* **Focus:** Unit tests only on **Service layer** (Business Logic) and **Domain Types** (TyDD validation).

## Where expected values come from

Every assertion's expected value comes from an artifact written **before** the implementation, by someone who had not yet seen the code:

* the spec's Testing Decisions;
* the ticket's acceptance criteria;
* for a small change with neither, the **expected line**: one or two sentences stating the observed behavior before the change (from the reproduction) and the required behavior after it, confirmed by the user before any code is written.

A test whose expected value was derived from the implementation tests the code as it is, not as it should be. When no artifact exists, write the expected line and get it confirmed; do not write the test.

## Proportion

Test code follows the size of the change:

* A bug fix earns one regression test that fails on the reproduction and passes after the fix. Not a suite.
* A feature earns one test per behavior named in its Testing Decisions or acceptance criteria, not one per branch.
* Test code larger than the code it covers is a signal to stop and check the artifact: either the behavior list is too long, or the tests are exercising implementation paths.

## Tooling and verification scripts

Scripts, harnesses, and evidence collectors that do not ship with the product receive no test suite. An optional smoke test that runs the script once on a fixture is the ceiling. Tooling that appears to need a suite has outgrown its purpose; shrink the tooling instead of testing it.

## File Structure

* No inline tests at file bottom.
* Follow the project's language and build system convention for test placement and naming (a `Tests/` target in SwiftPM, a `tests/` sibling in Rust or Python).
* Keep tests out of production builds through the build system's test target mechanism.

## Coverage

* Test behavior + domain invariants, not implementation details.
* Security tests from the **OWASP Testing Guide** when the change touches an exposed surface: network input, untrusted data, persisted data, or a permission boundary. A local utility with none of these has no OWASP surface.

## Test quality and anti-patterns

* **Implementation-coupled**: mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface). Tell: the test breaks on refactor with no behavior change.
* **Tautological**: the assertion recomputes the expected value the way the code does, so it passes by construction. Expected values come from an independent source of truth, such as a known-good literal, a worked example, or the spec's acceptance criteria. Never derive them using the same reasoning that produced the implementation.
* **Self-graded**: the same agent invocation that wrote the implementation also invented the test's expected values from scratch. It shares the implementation's blind spots by construction. The primary remedy is the artifact above, written before the code. An independent `code-review` pass is the second remedy, for medium and large changes.
