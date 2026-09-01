---
name: maintain-verification-skill
description: Audit project verification against source and runtime.
disable-model-invocation: true
---

# Maintain Verification Skill

Audit one project-local `verify-*` skill against current source and live public behavior. Correct drift inside the verification skill, report product regressions, and leave one verified working-tree change. This procedure never owns product fixes or delivery.

## When to Use

Use when:

- `/maintain-verification-skill` is requested;
- a verification command fails because its map or harness may have drifted;
- a release or accumulated runtime change warrants full capability coverage.

A normal task updates only the affected verification capability. Use this skill for a complete audit.

## Outcomes

Return exactly one outcome:

- **clean:** every mapped capability received source and live coverage, with no correction needed;
- **changed:** verified corrections exist only inside the selected verification-skill directory;
- **blocked:** exhaustive coverage could not finish, with the exact capability and blocker recorded.

## Procedure

### 1. Select the owner

Find project-local skills named `verify-*` with launch, doctor, drive, evidence, cleanup, isolation, and a capability map. Select the only candidate. Ask the user when several candidates cover distinct surfaces. Point to `/create-verification-skill` when none exists.

Record the selected directory as the write boundary. Capture `git status --short` before editing so unrelated work remains attributable.

Completion criterion: one verification skill and one write boundary are selected, or the run stops with an explicit missing or ambiguous owner.

### 2. Reconcile the index

Read the capability-map index and every sibling capability file. Resolve missing, duplicate, unindexed, and dead entries. Treat repository routes, commands, manifests, and `--help` output as source facts. Keep only operational knowledge whose rediscovery is expensive.

Completion criterion: the index and files form a one-to-one set before source analysis begins.

### 3. Run the source wave

Dispatch one read-only subagent per capability. Each subagent receives its capability file and must return:

- the public entry points and cited source paths;
- the current behavior visible to a user or client;
- likely map or harness drift;
- one live verification recipe;
- an explicit `none` when no drift is supported.

Subagents do not drive the artifact or edit files. Reconcile their citations and sweep recent user-facing source changes for missing capabilities.

Completion criterion: every mapped capability has one source report, and every proposed missing capability has a concrete public source path.

### 4. Plan one live pass

Merge compatible recipes into the fewest safe app states. Follow the selected skill's isolation contract. One coordinator owns all live driving. Parallel source reading does not imply parallel mutation of a shared runtime.

Preserve three invariants:

1. `Doctor` passes before the first drive, after surprising behavior, and for every fresh instance where instances are the isolation unit;
2. evidence already captured survives resets and cleanup;
3. processes and scratch state stop when their drive no longer needs them.

Completion criterion: every capability has a scheduled drive or a concrete prerequisite that makes it currently unreachable.

### 5. Drive every capability

Exercise each mapped public capability at least once. Reset or relaunch after a wedged state instead of continuing from uncertainty. Retry a harness correction once after re-running `Doctor`. Record an unreachable capability only with the attempted route and missing prerequisite.

A live mismatch is classified as:

- **map drift:** the product behavior is current and the capability prose is stale;
- **harness gap:** the public behavior works but the helper cannot drive or observe it;
- **product regression:** the expected public behavior fails through a valid drive;
- **environment blocker:** an external prerequisite prevents a valid drive.

Completion criterion: every capability has evidence and a classification, including explicit clean results.

### 6. Correct the verification owner

Edit only the selected verification-skill directory. Correct map drift and harness gaps, then re-drive every corrected capability. Keep product regressions and environment blockers out of the verification diff. Report them with evidence.

Review all helper comments against project coding standards. Preserve unrelated working-tree changes and the pre-run status.

Completion criterion: every verification edit has a passing live re-drive, and no path outside the write boundary changed because of this procedure.

### 7. Return the outcome

Run final cleanup after the last re-drive and confirm evidence remains readable. Report:

- outcome;
- capabilities covered;
- unreachable prerequisites;
- confirmed drift and corrections;
- product regressions;
- exact evidence locations;
- working-tree paths changed.

Leave commit and pull-request decisions to the project's delivery workflow.

Completion criterion: the outcome matches the coverage evidence, cleanup is complete, and every changed path is attributable.

## Pitfalls

- Source agreement does not replace the live pass.
- A broken product is not documentation drift.
- A healthy process can still hold a wedged user state.
- Editing product code hides the maintenance result's ownership.
- Concurrent drives can corrupt shared ports, databases, profiles, or sessions.
- Automatic commits or pull requests bypass the project's delivery decisions.

## Verification

Every mapped capability has source and live coverage, every correction was re-driven, product regressions remain product findings, the write boundary contains all procedure-owned edits, evidence survives cleanup, and the final outcome is `clean`, `changed`, or `blocked`.
