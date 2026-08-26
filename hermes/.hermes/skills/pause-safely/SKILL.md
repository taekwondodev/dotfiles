---
name: pause-safely
description: Suspend development work with enough evidence to resume safely.
disable-model-invocation: true
---

# Pause Safely

Suspend an active task without losing its decisions, evidence, repository state, or next criterion. Use before leaving, restarting Hermes, or reaching a context boundary.

## Procedure

1. Record the current task and active skill.
2. Record completed and incomplete steps, decisions, evidence, blockers, and open questions.
3. Inspect git status, diff, branch, tests, processes, and generated artifacts.
4. Save a handoff using the existing `handoff` contract.
5. State the exact next action and its completion criterion.
6. Leave external systems unchanged unless the user explicitly requested a durable update.

## Verification

A fresh session can locate the handoff, identify the current state, reproduce the important verification, and continue without guessing.
