---
name: menu
description: Browse available skills by name, category, or intended outcome.
disable-model-invocation: true
---

# Menu

`menu` is a read-only catalog for discovering skills. It explains what each available skill does and how it relates to the `dev-cycle` entrypoint. It does not start a workflow, modify files, change configuration, create issues, or alter the current task.

## When to Use

Use for:

- `menu`, to list all available skills;
- `menu <topic>`, to filter skills by topic or capability;
- `menu per fare <outcome>`, to find skills that can contribute to an intended result;
- comparing two skills before choosing a direct invocation.

Do not use `menu` when the user has already stated an objective and wants work performed. In that case, use `dev-cycle` or the explicitly requested skill.

## Source of Truth

Never maintain a hand-written catalog of skill names, descriptions, procedures, or routing rules.

- Use the live `skills_list` inventory for available skills and their descriptions.
- Use `skill_view` only when a description is insufficient to explain a distinction or relationship.
- Use the skill's actual frontmatter and body as the authority.
- Treat `dev-cycle` as the primary development entrypoint because its own skill definition says so.

If the catalog and a skill body disagree, report the disagreement rather than silently creating a third interpretation.

## Output Modes

### Full catalog

For `menu`:

1. Load the current skill inventory with `skills_list`.
2. Group results into:
   - primary entrypoints;
   - phase skills;
   - specialist skills;
   - principle skills;
   - project or platform skills;
   - plugin-provided skills, when identifiable.
3. Show every result exactly once.
4. Give each result a one-line purpose.
5. Mark whether it is normally routed through `dev-cycle`, directly invocable, or a principle/reference skill.

Do not invent categories that the inventory does not expose. If grouping requires inference from the skill name or description, label the grouping as inferred.

### Topic filter

For `menu architect`, `menu performance`, or another topic:

1. Load the current inventory.
2. Match names, descriptions, tags, related skills, and known capability terms.
3. Include direct matches first and useful supporting skills second.
4. Explain why each result matches.
5. State the skills that were considered but omitted only when that distinction helps the user choose.

Do not confuse a topic word with an invocation. `menu architect` describes the catalog; it does not run `architect`.

### Intended outcome

For `menu per fare X`:

1. Parse the intended outcome without starting work.
2. Identify the likely primary skill or entrypoint.
3. Identify supporting capabilities.
4. Order results by relevance.
5. Explain the role of each result and the normal composition.
6. Distinguish investigation, decision, implementation, verification, and delivery capabilities.
7. State whether the normal path starts at `dev-cycle` or whether a direct specialist invocation is appropriate.

Example shape:

```text
Outcome: diagnosticare un problema lento.

1. dev-cycle, entrypoint that coordinates the work.
2. grilling, separates facts from decisions.
3. investigation, traces the unknown cause.
4. runtime-forensics, if the process is live.
5. trace-forensics, if an artifact already exists.
6. perf-issue, for a single measured optimization.
7. hillclimb, for repeated measured improvements.
8. architect, if the solution changes a boundary or structure.
```

## Direct Invocation

`menu` never decides on behalf of the user and never invokes the result. It may identify `dev-cycle` as the normal path and explain a recommended composition, but the user or the active agent must start that work explicitly.

All skills shown by the catalog remain directly invocable according to their own contracts. A skill's appearance in `menu` does not grant permission to bypass source-of-truth owners, safety rules, human-owned decisions, or verification requirements.

## Verification

Before returning a catalog result:

- use the current skill inventory, not memory;
- do not claim an exhaustive list without enumerating the complete inventory;
- do not duplicate a skill in multiple groups unless the output explicitly marks the second appearance as a cross-reference;
- distinguish facts read from metadata from inferred relationships;
- do not start any listed skill or modify any state;
- identify stale or conflicting metadata instead of smoothing it over.
