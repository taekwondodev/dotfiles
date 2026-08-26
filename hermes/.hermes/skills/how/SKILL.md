---
name: how
description: Explain how a subsystem works, including flow, ownership, and boundaries.
disable-model-invocation: true
---

# How

Explain how a subsystem works well enough for a senior engineer to change it safely. Trace the real path from trigger to effect. Do not guess from filenames or produce an annotated source dump.

## When to Use

Use for:

- `how does X work?`;
- code walkthroughs before a change;
- ownership and placement questions;
- layering and dependency questions;
- runtime flow questions.

Use `why` for motivation and historical rationale. Use `architect` when the question becomes a new structural decision.

## Procedure

1. Define the scope and state the interpretation if the request is ambiguous. Do not ask when repository inspection can resolve the ambiguity.
2. Use `search_files` and `read_file` to find the entry point, callers, callees, types, persistence or external effects, and tests.
3. Trace the flow from input or trigger to output or effect. Follow symbols across module boundaries.
4. Record ownership, dependency direction, validation, error conversion, observability, and security boundaries.
5. Use `delegate_task` for independent read-only exploration when the subsystem is broad. Keep each worker on a distinct angle and synthesize the artifacts yourself.
6. Present the explanation with overview, key concepts, flow, where things live, and gotchas.

## Verification

Before presenting the result:

- every claimed flow step has a source file and symbol;
- callers and callees were followed across each relevant boundary;
- surprising behavior is marked as observed rather than inferred;
- open uncertainty is explicit;
- no code or project state was modified.
