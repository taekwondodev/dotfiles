---
name: to-spec
description: Turn the current conversation into a spec and publish it to the project issue tracker (no interview, just synthesis of what you've already discussed).
disable-model-invocation: true
---

This skill takes the current conversation context and codebase understanding and produces a spec. Do NOT interview the user. Just synthesize what you already know. If real gaps remain, read the `grilling` skill (and `domain-modeling` too if the gap is a domain term) for just those gaps, not a full re-interview.

**This step is user-invoked**: do not start it on your own; the user triggers it explicitly.

The issue tracker and issue-label vocabulary should have been provided to you. Tell the user to run `/dev-cycle-setup` if not; it's user-invoked, so you can't call it yourself.

Read `writing-for-agents` before drafting the spec. Its general writing rules govern this document; the spec template below adds only spec-specific structure and the budget per section.

When invoked with an issue reference, first read `docs/agents/issue-tracker.md` and fetch the issue's full body, comments, and labels through the configured tracker. Use that issue as the source material, update the same issue with the completed spec and its label transition, and do not create a duplicate issue for the same request. Resolve the configured label strings through `docs/agents/triage-labels.md`; do not assume canonical state names are the tracker labels.

When invoked with a `wayfinder` map whose frontier is empty, read the map's Decisions-so-far and the full body of each closed ticket. That is the source material, not the conversation.

## Budget

A spec is a decision record, not a manual. Each section has a budget below; the whole spec stays under 800 words excluding the template headings. When a section wants more, the material is either a decision that belongs in an ADR, a procedure that belongs in a ticket's acceptance criteria, or detail the implementer can read from the code. Move it there or cut it.

A section that would exceed its budget is a signal that the work is oversized for one spec. Say so to the user instead of writing a longer spec.

## Evidence and principles

Carry forward the selected `/architect` sketch and any `how`, `why`, `investigation`, or `prototype` evidence that changed a decision. Load `blast-radius` when a contract, data shape, migration, or shared symbol may affect consumers beyond the obvious scope; the confirmed consumers and unproven risks must shape Architecture, Implementation Decisions, Testing Decisions, and Out of Scope.

Load the canonical principle when its trigger fires:

- `principle-experience-first` changes Solution and Out of Scope toward the user outcome rather than implementation convenience.
- `principle-outcome-oriented-execution` describes the intended end state and keeps temporary migration states from becoming accidental requirements.

Record a principle only where the spec can name the decision it changed. Evidence supports a decision; it does not silently expand product scope.

## Process

1. Explore the repo to understand the current state of the codebase, if you haven't already. Use `docs/agents/domain.md`'s glossary vocabulary throughout the spec, and respect any ADRs in the area you're touching.

2. For code-shaped work, use `/architect` to ground the caller, data shape, ownership, boundaries, and threat model before placing the feature against its layers and bounded contexts. Prefer extending an existing bounded context to creating a new one; a new context is a real decision, not a default. Check with the user that the layer/context split matches their expectations before writing it into the spec.

3. Sketch out where this will be tested, per `/testing`'s scope. Use the highest existing seam possible; new seams are a real decision, not a default.

4. Write the spec using the template below, check every section against its budget, then publish it to the project issue tracker. Apply the configured `ready-for-agent` state label; no additional triage step is needed. When completing an issue, replace the configured `needs-grilling` state with `ready-for-agent`.

<spec-template>

## Problem Statement

The problem that the user is facing, from the user's perspective. Budget: one paragraph, at most 80 words.

## Solution

The solution to the problem, from the user's perspective. Budget: one paragraph, at most 120 words.

## User Stories

A numbered list of user stories, each in the format:

1. As an <actor>, I want a <feature>, so that <benefit>

Budget: at most 6 stories. One story per distinct user-visible outcome; stories that restate the same outcome under different conditions collapse into one. Constraints and failure behavior go in Implementation Decisions, not in stories.

## Architecture

Which layer(s) this touches (Handler/Service/Repository/Middleware, per `/architect`), and which bounded context(s). State explicitly:

- Whether this is a new bounded context or an extension of an existing one, and why
- Any port a service needs, and which layer implements it
- Shared-kernel implications, if this reaches across contexts
- Any domain error type this introduces, and which layer owns it

Budget: at most 6 bullets. When nothing changes at a layer, omit it.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Schema changes
- API contracts
- Specific interactions
- Dependency additions, if any, with the `/coding-standards` justification for each

Budget: at most 8 bullets, one decision each. A decision that needs its own paragraph of rationale goes in an ADR, with the bullet pointing at it.

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts. This is not a working demo, just the important bits.

## Testing Decisions

A list of testing decisions that were made, scoped by `/testing`'s rules. Include:

- Which Service-layer and Domain-Type units get test coverage, and the expected behavior/values each asserts. `/implement` writes tests against this, not values invented during implementation
- Prior art for the tests (i.e. similar types of tests in the codebase)
- Any OWASP-relevant security test called for by `/testing`'s coverage rule

Budget: at most 6 bullets. Name the behaviors to prove and the seam; list neither test case names nor an apparatus. A verification apparatus larger than the change is a separate decision the user makes, not a Testing Decision.

## Out of Scope

The things that are out of scope for this spec. Budget: at most 5 bullets.

## Further Notes

Anything that does not fit above. Budget: at most 80 words; usually empty.

</spec-template>
