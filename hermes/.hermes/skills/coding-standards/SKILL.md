---
name: coding-standards
description: >
  Coding standards, TyDD philosophy, dependency management, and version lookup protocol.
  Invoke when writing, reviewing, or refactoring code, adding a dependency, or when user
  mentions coding style, types, security defaults, library choices, or API versions.
---

## Research & Knowledge Retrieval

* Documentation first: verify the latest official docs + community best practices before solving.
* No hallucinations: if unsure about a lib version or API, say so and ask the user to check.
* Prefer verified sources over memory. The research flow below makes this cheap and context-safe:

### Research flow

The goal is *verified, context-lean* findings: pull only what a decision needs, never a page
dump. In order:

1. **Search, then extract**. Search to find sources (returns URL/title/description),
   then pull clean markdown from the relevant hits. This is the native equivalent of
   "search then read"; do it yourself, in-session.
2. **Browser for interaction**: when a page needs real navigation (a flow, a click-through, a
   dynamic render, or extraction is blocked), drive the browser instead.
3. **Delegate long research**. For a broad or multi-source question that would flood your context,
   hand it to a subagent in an isolated context and aggregate its result. This
   is what `wayfinder` research tickets do. See the `wayfinder` skill.
4. **Compression is built-in**: clean page content comes back directly (truncation and large-page spill to disk are handled for you); rely on that instead of pasting raw HTML into context.

## Version & API Lookup (Mandatory)

* NEVER answer lib versions, API signatures, or breaking changes from memory.
* ALWAYS verify against current docs or changelog first, using the research flow above
  (search → extract, browser if needed, delegate for breadth).
* Cite what you found (URL or source), so the user can trust the version without re-checking.

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
* No comments by default. A comment is allowed only when it records a non-obvious WHY that the code cannot express more clearly. Never explain WHAT the code does.
* This no-comments rule applies equally to production code, tests, scripts, migrations, configuration, verification harnesses, and generated artifacts. Review every comment against the rule before declaring work complete.
* DRY, modern idioms, zero-cost abstractions.
* **Low cognitive complexity:** minimize branching, nesting, and hidden control flow. Decompose by domain responsibility, not merely to satisfy complexity metrics.
* **Fail fast:** missing required config = unrecoverable error. Crash early.
* **Secure defaults:** insecure = explicit opt-in, never opt-out.
* **Validate once, then trust:** convert untrusted input into types that enforce their intrinsic invariants at the earliest entry point. Internal code trusts those types and never repeats validation or recomputes established facts. Context-dependent rules remain with the code that owns the required state and decisions.
* **Least privilege:** request only minimum permissions needed.
* **Secrets hygiene:** never in logs, errors, traces, comments. Hardcoded secret = build-breaking bug.
