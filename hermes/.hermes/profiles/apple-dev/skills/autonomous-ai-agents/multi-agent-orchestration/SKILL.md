---
name: multi-agent-orchestration
description: "Use for multi-agent work. Keep one lead; verify delegation."
version: 1.0.0
license: MIT
metadata:
  hermes:
    tags: [multi-agent, orchestration, delegation, bots, group-chat, software-development, review]
---

# Multi-Agent Orchestration

Use this skill when a software task benefits from independent analysis, specialist review, or persistent agent collaboration. The goal is not to maximize the number of agents: it is to reduce blind spots while preserving one coherent decision-maker.

## Core operating model

Maintain one accountable lead agent. The lead owns the user relationship, project context, phase gates, architectural decisions, integration, and final verification. Specialist agents provide evidence, alternatives, implementation in isolated workspaces, or read-only review; they do not silently redefine scope.

Prefer a small team:

- **Lead/orchestrator:** requirements, checkpoints, synthesis, integration, verification.
- **UI specialist:** native UI hierarchy, sizing, accessibility, visual states, rendering.
- **Concurrency/domain specialist:** async boundaries, cancellation, state ownership, provider/domain correctness.
- **Testing specialist:** test strategy, fixtures, transitions, resources, build/runtime evidence.
- **Release specialist:** packaging, installation, regression and release readiness.

Create only the specialists needed for the task. A single agent is preferable for a small, well-understood change.

## Phase-gated workflow

1. **Grill first** when requirements, UX, architecture, or edge cases are uncertain.
2. **Stop at a human checkpoint.** Do not create code or tickets merely because grilling produced a plausible direction.
3. **Write the spec and tickets** after the user chooses the direction.
4. **Delegate independent analysis in parallel** with explicit outputs and read-only boundaries.
5. **Synthesize before implementing.** Resolve disagreements in the lead context; do not average incompatible recommendations.
6. **Implement in one designated workspace.** Other code-writing agents use isolated worktrees or branches.
7. **Run independent reviews** against the spec and the implementation. Reviewers should not modify code unless explicitly assigned.
8. **Verify the artifact for real:** build, tests, resource/bundle checks, launch/runtime checks, and UI inspection where relevant.
9. **Report evidence and remaining uncertainty** rather than claiming completion from agent self-reports.

## Delegation contract

Every delegated task should state:

- the exact question or deliverable;
- the repository/project and relevant files;
- whether edits are forbidden, isolated, or allowed;
- the required output format;
- acceptance criteria and verification expected;
- dependencies and assumptions that must not be invented.

For parallel work, make subtasks independent. Do not delegate a task that requires another child’s unverified output unless the dependency is passed explicitly after verification.

## Persistent bot teams and group rooms

Use persistent Hermes profiles when a specialist will be reused across sessions or needs its own memory, skills, model, or routine. Use ephemeral delegation for bounded subtasks that do not need durable identity.

A group room is useful for kickoff, debate, and shared status. It is not a substitute for orchestration: the lead still converts discussion into decisions, checkpoints, tickets, and verified changes. Keep group memberships small enough to stay legible; Hermes group rooms support 2–6 bots.

At group creation:

1. give each bot a narrow role and a description;
2. include the lead and only the specialists relevant to the project;
3. post a kickoff stating who coordinates, that the user owns decision checkpoints, and whether members are read-only;
4. ask each member for a concise role confirmation and proposed collaboration protocol;
5. distinguish `thinking`, `replied`, and `verified`—a response is not evidence of completed work;
6. use threads for feature-specific discussions so the room remains navigable.

## Safe collaboration rules

- Never let several agents edit the same checkout concurrently.
- Prefer read-only reviews before granting write access.
- Keep secrets and provider credentials out of prompts, transcripts, and group messages.
- Do not treat a bot’s claim of success as proof; inspect the file, test output, artifact, or external record yourself.
- Do not let a group conversation bypass the project’s human checkpoint or dev-cycle phase.
- Do not create recurring routines until the task is understood and the desired cadence is explicit.

## Output patterns

For specialist reviews, prefer:

```text
Role
Findings (severity, evidence, file/area)
Open decisions
Recommended next step
Verification still required
```

For the lead synthesis, prefer:

```text
Consensus
Disagreements
Decision needed from user
Implementation boundary
Acceptance checks
```

## Hermes reference

For the validated Hermes Bot Mode setup, group-room behavior, and CLI/profile parity, see `references/hermes-bot-room.md`.
