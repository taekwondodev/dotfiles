# CLAUDE.md - Project Guidelines

## 1. Research & Knowledge Retrieval
* **Documentation First:** Verify latest official docs + community best practices before solving.
* **No Hallucinations:** Unsure about lib version or API? Say so, ask user to check.

## 1.1 Version & API Lookup (Mandatory)
* **NEVER** answer lib versions, API signatures, breaking changes from memory.
* **ALWAYS** call `WebSearch` or `WebFetch` first for current docs or changelog.
* If lookup impossible, state: "I cannot verify this — my training data is from August 2025."

## 2. Dependency Management
* **Minimalism:** Prefer stdlib over external deps.
* **Justification:** Add dep only if massive benefit (perf, complexity) stdlib can't handle.
* **Vetting:** Must be widely used, actively maintained, consistent with project.
* **Security Vetting:** Check CVE history, run audit (`npm audit`, `cargo audit`, `govulncheck`). Prefer deps with security disclosure policy.
* **License Compliance:** Verify license compatible with distribution model. Flag copyleft (GPL).

## 3. Coding Standards & Philosophy
* **Type-Driven Design (TyDD):** Core philosophy. Encode constraints into type system. Make invalid states unrepresentable.
* **Breaking Changes & Evolution:**
    * **No Backward Compatibility:** Modify structures/APIs destructively. No legacy fields or methods.
    * **Refactor Fearlessly:** Change structure if needed for feature or optimization. Prioritize correctness of *current* version.
* **Encapsulation & Module Strategy:**
    * **Visibility:** Default private. Expose publicly only if strictly needed.
    * **Flattened Hierarchy:** Private submodules + explicit re-exports in parent. Short imports for consumer.
    * **Explicit Paths:** No deep nested imports. Clean, explicit access.
* **Self-Documenting Code:** No comments if code is readable. Only explain WHY, never WHAT.
* **DRY & Modern:** Consistent, DRY, modern idioms.
* **Optimization:** Zero-cost or low-overhead abstractions.
* **Configuration Handling:** Fail Fast. Missing required config = unrecoverable error. Crash early with clear message.
* **Secure Defaults:** Secure by default. Insecure = explicit opt-in, never opt-out.
* **Input Validation at Boundaries Only:** Validate at Handler layer only. Internal layers use already-validated types.
* **Principle of Least Privilege:** Request only minimum permissions needed.
* **Secrets Hygiene:** Secrets MUST NOT appear in logs, errors, stack traces, comments. Hardcoded secret = build-breaking bug.

## 4. Architecture Design
* Invoke `/design` skill when: new feature, new module, new class, structural refactoring.

## 5. Testing Strategy
* Invoke `/testing` skill when: writing tests or setting up test suite.

## 6. Interaction Protocol
* **Ambiguity Protocol (80% Rule):** Confidence < 80% on scope/intent/constraints? Ask clarifying questions. No code or advice until threshold met.
* **Output Format:** No external `.md` files. All explanations in chat.
* **Implementation Flow:** Explain approach + show snippet, ask "Want me to implement this directly?". Wait for confirmation before touching files.
* **Refactoring:** Spot optimization/readability/TyDD opportunity? Propose immediately.

