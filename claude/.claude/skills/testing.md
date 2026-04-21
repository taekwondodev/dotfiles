# Testing Strategy

## Scope & Exclusions
* **STRICTLY NO** unit tests for **Handlers** (Input/HTTP layer).
* **STRICTLY NO** unit tests for **Repositories** (Data Access layer).
* **Focus:** Concentrate all unit testing efforts solely on the **Service layer** (Business Logic) and **Domain Types** (TyDD validation).

## File Structure
* Do not put tests inline at the bottom of the source file.
* Create a `tests/` directory at the same level as the module being tested.
* Name test files consistently with the module they test (e.g., `request_test` for `request`).
* Declare test modules conditionally so they are excluded from production builds.

## Coverage
* Test behavior and domain invariants, not implementation details.
* Security tests must follow the **OWASP Testing Guide** as the reference standard for what to cover and how to approach security validation.
