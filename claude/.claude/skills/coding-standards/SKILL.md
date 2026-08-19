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
* Prefer verified sources over memory. Hermes' research flow makes this cheap and context-safe:

### Hermes research flow

The goal is *verified, context-lean* findings: pull only what a decision needs, never a page
dump. In order:

1. **Search, then extract**. Start with `web_search` to find sources (returns URL/title/description),
   then `web_extract` on the relevant hits to pull clean markdown. This is the native equivalent of
   "search then read"; do it yourself, in-session.
2. **Browser for interaction**: when a page needs real navigation (a flow, a click-through, a
   dynamic render, or `web_extract` is blocked), use `browser_exec` / `browser_navigate`.
3. **Delegate long research**. For a broad or multi-source question that would flood your context,
   hand it to a subagent via `delegate_task` (isolated context, background, aggregated result). This
   is what `wayfinder` research tickets do. See the `wayfinder` skill.
4. **Compression is built-in**: `web_extract` returns clean page content directly (Hermes handles truncation and large-page spill to disk itself); rely on that instead of pasting raw HTML into context.

## Version & API Lookup (Mandatory)

* NEVER answer lib versions, API signatures, or breaking changes from memory.
* ALWAYS verify against current docs or changelog first, using the research flow above
  (`web_search` → `web_extract`, browser if needed, `delegate_task` for breadth).
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
* **No comments** unless WHY is non-obvious. Never explain WHAT.
* DRY, modern idioms, zero-cost abstractions.
* **Fail fast:** missing required config = unrecoverable error. Crash early.
* **Secure defaults:** insecure = explicit opt-in, never opt-out.
* **Validate at boundaries only:** Handler layer validates. Internal layers trust already-validated types.
* **Least privilege:** request only minimum permissions needed.
* **Secrets hygiene:** never in logs, errors, traces, comments. Hardcoded secret = build-breaking bug.
