---
name: coding-standards
description: >
  Coding standards, TyDD philosophy, dependency management, and version lookup protocol.
  Invoke when writing, reviewing, or refactoring code, adding a dependency, or when user
  mentions coding style, types, security defaults, library choices, or API versions.
---

## Research & Knowledge Retrieval

* Documentation first: verify latest official docs + community best practices before solving.
* No hallucinations: unsure about lib version or API? Say so, ask user to check.

## Version & API Lookup (Mandatory)

* NEVER answer lib versions, API signatures, breaking changes from memory.
* ALWAYS call `WebSearch` or `WebFetch` first for current docs or changelog.

## Dependency Management

* Prefer stdlib over external deps.
* Add dep only if massive benefit (perf, complexity) stdlib can't handle.
* Must be widely used, actively maintained, consistent with project.
* Security: check CVE history, run audit (`npm audit`, `cargo audit`, `govulncheck`). Prefer deps with security disclosure policy.
* License: verify compatible with distribution model. Flag copyleft (GPL).

## Coding Philosophy

* **TyDD:** Encode constraints into type system. Make invalid states unrepresentable.
* **No backward compatibility:** modify structures/APIs destructively. No legacy fields or methods.
* **Refactor fearlessly:** prioritize correctness of current version.
* **Visibility:** default private. Expose publicly only if strictly needed.
* **Flattened hierarchy:** private submodules + explicit re-exports in parent.
* **No comments** unless WHY is non-obvious. Never explain WHAT.
* DRY, modern idioms, zero-cost abstractions.
* **Fail fast:** missing required config = unrecoverable error. Crash early.
* **Secure defaults:** insecure = explicit opt-in, never opt-out.
* **Validate at boundaries only:** Handler layer validates. Internal layers trust already-validated types.
* **Least privilege:** request only minimum permissions needed.
* **Secrets hygiene:** never in logs, errors, traces, comments. Hardcoded secret = build-breaking bug.
