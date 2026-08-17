---
name: to-spec
description: Turn the current conversation into a spec and publish it to the project issue tracker — no interview, just synthesis of what you've already discussed.
disable-model-invocation: true
---

This skill takes the current conversation context and codebase understanding and produces a spec. Do NOT interview the user — just synthesize what you already know. If real gaps remain, read the `grilling` skill (and `domain-modeling` too if the gap is a domain term) for just those gaps, not a full re-interview.

**This step is user-invoked**: do not start it on your own — the user triggers it explicitly (normally after grilling's hand-off). The pipeline, its checkpoints, and the invocation rules live in the `dev-cycle` skill — read it before proceeding.

The issue tracker and triage label vocabulary should have been provided to you — tell the user to run `/dev-cycle-setup` if not; it's user-invoked, so you can't call it yourself.

This is also where `/wayfinder` hands off: when a map's frontier empties, its closed tickets and Decisions-so-far feed this skill instead of going straight to `/implement` — collapsing decisions scattered across many tickets into one buildable spec.

## Process

1. Explore the repo to understand the current state of the codebase, if you haven't already. Use `docs/agents/domain.md`'s glossary vocabulary throughout the spec, and respect any ADRs in the area you're touching. If this spec closes out a `/wayfinder` map, read the map's Decisions-so-far and the full body of each closed ticket — that's the source material, not the conversation.

2. Place the feature against `/design`'s layers (Handler/Service/Repository) and bounded contexts. Prefer extending an existing bounded context to creating a new one; a new context is a real decision, not a default. Check with the user that the layer/context split matches their expectations before writing it into the spec.

3. Sketch out where this will be tested, per `/testing`'s scope — not an oversight to flag if it excludes a layer. Use the highest existing seam possible; new seams are a real decision, not a default.

4. Write the spec using the template below, then publish it to the project issue tracker. Apply the `ready-for-agent` triage label — no need for additional triage.

<spec-template>

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list of user stories should be extremely extensive and cover all aspects of the feature.

## Architecture

Which layer(s) this touches (Handler/Service/Repository/Middleware, per `/design`), and which bounded context(s). State explicitly:

- New bounded context, or extending an existing one — and why
- Any port a service needs, and which layer implements it
- Shared-kernel implications, if this reaches across contexts
- Any domain error type this introduces, and which layer owns it

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Schema changes
- API contracts
- Specific interactions
- Dependency additions, if any, with the `/coding-standards` justification for each

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

## Testing Decisions

A list of testing decisions that were made, scoped by `/testing`'s rules. Include:

- Which Service-layer and Domain-Type units get test coverage, and the expected behavior/values each asserts — `/implement` writes tests against this, not values invented during implementation
- What makes a good test here (behavior + domain invariants, not implementation details)
- Prior art for the tests (i.e. similar types of tests in the codebase)
- Any OWASP-relevant security test called for by `/testing`'s coverage rule

## Out of Scope

A description of the things that are out of scope for this spec.

## Further Notes

Any further notes about the feature.

</spec-template>
