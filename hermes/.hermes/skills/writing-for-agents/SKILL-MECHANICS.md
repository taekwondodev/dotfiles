# Skill mechanics

The skill-specific branch of [`writing-for-agents`](SKILL.md): what changes when the document is a skill: frontmatter, invocation choice, and router skills. Everything else about writing it is the universal reference in `SKILL.md`.

The skill-authoring workflow must read `writing-for-agents` before creating or editing a skill. This file adds skill-specific mechanics only; it does not override the general writing rules.

## Isolation

A skill is complete from its own text plus the explicit procedural inputs it names.

- Reference another skill or document only as an actionable dependency. State when it is loaded and which result this procedure consumes.
- Keep policy provenance out of the skill. Agent configuration, system prompts, project instruction files, and earlier conversations do not supply missing behavior.
- Write the required behavior locally when this skill owns it. When another skill owns a procedure, load it and consume its result without restating or defending its policy.
- A continuity skill may consume a named handoff, transcript, issue, branch, or session-search result only when it defines how to retrieve the artifact and reconcile it with live state. It must not assume the artifact's contents.
- Review every cross-reference before completion. Keep explicit procedural inputs and remove references that only explain where a rule originated.

Completion criterion: the skill remains interpretable in a fresh invocation, and every external reference has a local trigger and a named result.

## Invocation

Two choices, trading the two loads:

- A **model-invoked** skill keeps a `description`, so the agent can fire it autonomously, and other skills can reach it. You can still type its name: model-invocation always _includes_ user reach; a description only ever adds agent discovery, never removes the human's. The description is the skill's top-level context pointer, forced to stay loaded at all times. That is permanent context load in exchange for discoverability. A model-invoked skill whose content is all reference is also one home for shared reference: another skill can invoke it, so reference needed by several skills lives in one place. Mechanics: omit `disable-model-invocation`, and write a model-facing description carrying the trigger branches (the pointer-writing rules in `SKILL.md` apply in full).
- A **user-invoked** skill strips the description from the agent's reach: only the human typing its name can invoke it, and no other skill can. Zero context load, but it spends cognitive load because you are the index that must remember it exists. Mechanics: set `disable-model-invocation: true`; the `description` becomes human-facing: a one-line summary, trigger lists stripped.

Pick model-invocation only when the agent must reach the skill on its own, or another skill must. If it only ever fires by hand, make it user-invoked and pay no context load.

Shared reference that two user-invoked skills both need can live in neither. With no descriptions, neither can fire the other. Push it to a plain file outside the skill system: external reference any skill can point at.

## Splitting by invocation

The invocation cut of splitting (the sequence cut lives in `SKILL.md`): split off a model-invoked skill for either of two reasons. It has a distinct leading word that should trigger it on its own, meaning a trigger word you actually use in your prompts, or another skill must reach it. You pay context load for the new always-loaded description, so that independent reach has to be worth it.

## Router skills

When user-invoked skills multiply past what you can remember, that piled-up cognitive load is cured by a **router skill**: one user-invoked skill that names the others and when to reach for each, so the human has one skill to remember instead of many. It can only hint, never fire them: user-invoked skills have no description, so nothing but the human can reach them.
