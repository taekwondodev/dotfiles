---
name: create-verification-skill
description: Create a project-local skill for repeatable runtime proof.
---

# Create Verification Skill

Generate one project-local `verify-<app>` skill that launches the real artifact, drives public behavior, captures evidence, and cleans up its own runtime state. Prefer an existing end-to-end harness over new tooling. The generated skill is the durable interface; this generator is setup machinery.

## When to Use

Use when:

- `dev-cycle-setup` offers optional runtime verification and the user accepts;
- a project has no repeatable way for an agent to prove public runtime behavior;
- an existing harness works but cold agents cannot discover or operate it reliably.

Use the existing project verification skill when one already covers the target surface. Extend that skill rather than generating a sibling for the same surface.

## Procedure

### 1. Interview the repository

Read project rules, manifests, documented run commands, existing tests, development scripts, routes, commands, and user-facing entry points. Establish:

- **Surface:** the web UI, desktop app, CLI, TUI, API, service, library, or mobile app a user or client touches;
- **Launch:** the repository-owned command, required dependencies, readiness signal, ports, data, authentication, and teardown;
- **Drive:** the existing harness or the smallest public interaction path available;
- **Evidence:** observable output, responses, screenshots, traces, logs, exit codes, or persisted effects;
- **Isolation:** the ports, data directories, profiles, containers, or processes that let concurrent runs avoid shared state.

Ask only for product, security, credential, or environment decisions that repository and runtime inspection cannot establish. A broken base blocks generation until it is fixed or reported precisely.

Completion criterion: every item above has an observed answer or an explicit blocker, and the chosen surface is singular.

### 2. Choose the smallest lever

Prefer, in order:

1. an existing end-to-end or control harness;
2. a thin wrapper around stable project commands;
3. a focused helper for the uncovered interaction path.

Use machine-readable output and stable public handles. Give destructive operations an observable safe mode when the project supports one. Return actionable errors and useful `--help` output. Keep helpers inside the generated skill unless the repository already owns the harness elsewhere.

Completion criterion: the chosen lever covers launch, health, one public drive, evidence, and cleanup without duplicating an existing owner.

### 3. Generate the project skill

Write `.hermes/skills/verify-<app>/SKILL.md` with model-invoked frontmatter. Its description names the app, public surface, and runtime claims that should load it. Do not set `disable-model-invocation`.

The body owns these sections:

- **Launch:** exact startup and readiness procedure, plus teardown;
- **Doctor:** one read-only check that identifies the intended instance and answers whether it is safe to drive;
- **Drive:** public commands or stable selectors grounded in this repository;
- **Evidence:** the action, resulting state, side effects, artifact location, and pass condition;
- **Cleanup:** terminate only processes or instances created by the run, remove scratch state, and preserve evidence;
- **Isolation:** state whether parallel drives are safe and which resources separate them.

Write executable helpers under the generated skill when needed and document their exact invocation. Repository-owned commands remain the source of truth, so link to them instead of copying their implementation or `--help` output.

Completion criterion: a cold agent can identify the instance, execute one drive, judge the result, and clean up using only the generated skill and its retrievable project sources.

### 4. Trust and prove discovery

Resolve the repository root and check whether Hermes trusts it for repo-local skills. When trust is absent, explain that repo-local skills contribute agent instructions and ask before running `hermes skills trust <repo-root>`. Trust only the exact repository root, never a parent directory.

After trust is present, start a fresh Hermes process whose workdir resolves to the trusted repository root and inspect its skill index for the exact generated `verify-<app>` name. The current process can retain a cached index, and a process anchored to another workdir cannot discover the project skill.

Completion criterion: a fresh process discovers the exact generated skill from the trusted repository, or generation stops with an explicit declined-trust blocker.

### 5. Seed the capability map

Read [`references/feature-map-format.md`](references/feature-map-format.md). Under the generated skill's `references/features/` directory, create a Markdown README index plus one file for each of the top three to five public capabilities visible in routes, commands, menus, or project documentation. Use a name appropriate to the surface, such as feature map, command map, API flow map, or capability map.

Each capability records what the user or client does, how the harness drives it, what observable result proves it, and its prerequisites or gotchas. The map points to repository sources rather than caching facts that are cheap to rediscover.

Completion criterion: every indexed capability resolves to one file, every file resolves from the index, and each capability names a runnable proof or an explicit current gap.

### 6. Prove the generated skill

Follow the generated instructions without substituting unpublished knowledge:

1. launch the intended instance;
2. run `Doctor`;
3. drive one mapped public capability;
4. capture the named evidence;
5. clean up all runtime state created by the attempt;
6. confirm the evidence still exists after cleanup.

Clean up after every failed iteration. Revise the skill or helper and repeat until the full sequence passes. A generated but unexecuted skill is a draft.

Completion criterion: one mapped capability passes end to end, cleanup leaves no owned process or scratch state, and the surviving evidence is readable.

### 7. Hand off maintenance

Report the generated path, project-trust state, fresh-discovery result, proven capability, exact proof command, evidence location, isolation limit, and uncovered capabilities. Point to `/maintain-verification-skill` for a full drift audit. The current session may need to restart before project-skill discovery reflects the new files.

Completion criterion: the user can reproduce the proof and knows the remaining coverage boundary.

## Pitfalls

- A build or unit test is not a public runtime drive.
- A test-only setter or internal endpoint proves less than the user path it bypasses.
- A helper that restates project commands becomes a stale cache.
- Process-name cleanup can terminate unrelated work. Track and terminate owned identities.
- Shared ports, databases, profiles, or user sessions make parallel drives unsafe until isolated.
- Screenshots show state, not necessarily the action that produced it. Capture both when the surface is visual.
- Secrets and production data never belong in helpers, evidence, fixtures, or generated prose.

## Verification

The generated skill is project-local, model-invoked, source-grounded, isolated where the project permits, proven on one public capability, and leaves durable evidence after complete cleanup.
