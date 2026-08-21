---
name: domain-modeling
description: Build and sharpen a project's domain model. Use when the user wants to pin down domain terminology or a ubiquitous language, record an architectural decision, or when another skill needs to maintain the domain model.
---

# Domain Modeling

Actively build and sharpen the project's domain model as you design. This is the *active* discipline: challenge terms, invent edge-case scenarios, and write the glossary and decisions down the moment they crystallise. (Merely *reading* `CONTEXT.md` for vocabulary is not this skill. That's a one-line habit any skill can do. This skill is for when you're changing the model, not just consuming it.)

Read `writing-for-agents` before writing `CONTEXT.md` entries or ADRs. Its general writing rules govern those documents; the context and ADR formats below add only domain-specific structure.

`CONTEXT.md` and `docs/adr/` are project-local files, never CLAUDE.md. CLAUDE.md stays a router of pointers, and this skill owns the content behind them.

## File structure

`dev-cycle-setup` decided the layout for this repo once already: single-context (`CONTEXT.md` + `docs/adr/` at the root) or multi-context (`CONTEXT-MAP.md` fanning out to one `CONTEXT.md`/`docs/adr/` pair per bounded context). See `docs/agents/domain.md` for the diagram; this skill just writes into whichever layout is already there, never re-decides it.

Create files lazily, only when you have something to write. If no `CONTEXT.md` exists, create one when the first term is resolved. If no `docs/adr/` exists, create it when the first ADR is needed.

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in `CONTEXT.md`, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y. Which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account': do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible. Which is right?" Locate the contradiction by `/design`'s layers (Handler/Service/Repository) so the fix lands in the layer that actually owns the rule: usually Service, never Handler or Repository.

### Update CONTEXT.md inline

When a term is resolved, update `CONTEXT.md` right there. Don't batch these up. Capture them as they happen. Use the format in [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md).

`CONTEXT.md` should be totally devoid of implementation details. Do not treat `CONTEXT.md` as a spec, a scratch pad, or a repository for implementation decisions. It is a glossary and nothing else.

### Offer ADRs sparingly

Only offer to create an ADR when all three are true:

1. **Hard to reverse**: the cost of changing your mind later is meaningful
2. **Surprising without context** means a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off**, where genuine alternatives existed and you picked one for specific reasons

If any of the three is missing, skip the ADR. Use the format in [ADR-FORMAT.md](./ADR-FORMAT.md).

## Where this gets invoked

- `/grill-with-docs` drives this skill throughout its interview, so `CONTEXT.md`/ADRs update as the conversation goes, not after.
- `/wayfinder`'s **Grilling** ticket type invokes this alongside `/grilling` whenever the decision is code-shaped.
