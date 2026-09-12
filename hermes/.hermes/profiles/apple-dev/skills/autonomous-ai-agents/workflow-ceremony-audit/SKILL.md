---
name: workflow-ceremony-audit
description: Use when small requests balloon. Right-size workflow skills.
version: 0.1.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
metadata:
  hermes:
    tags: [skills, workflow, dev-cycle, audit, proportionality]
---

# Workflow Ceremony Audit

Diagnose why an agent workflow library turned a small request into days of specs, tickets, reviews, and verification apparatus, then edit the skills so the next small request stays small. The user's standing stance: ceremony follows the size of the change; a fix to error handling or a sync-versus-async comparison on a personal utility is a small or medium task, never a campaign.

## When to Use

- The user says a change "should have been simple" and asks whether the workflow makes sense.
- Specs, tickets, reviews, or verification tooling visibly outgrow the product change.
- A workflow skill library (router + phase skills + principles) needs a proportionality pass.

Don't use for a single skill's prose fix with no sizing or routing question.

## Procedure

1. **Measure before opining.** In the project repo, gather with `terminal`: lines of product code versus verification tooling and evidence directories (`find ... | xargs wc -l`, `du -sh`), word counts of the spec issues (`gh issue view N --json body --jq .body | wc -w`), tickets spawned per request (`gh issue list --state all --json number,title,labels,createdAt,closedAt`), and elapsed dates from `git log`. Completion: a table the user can read in ten seconds. Verification apparatus larger than the product is the diagnostic signal.
2. **Grep the workflow skills for sizing vocabulary** (`small|trivial|proportion|skip|budget|lightweight`) with `search_files`. Zero hits in the router means every task is promoted to the full path. Also list promotion triggers; "architecture", "ownership", "durable decision" fire on every change in a small app and must be narrowed to persisted formats, external contracts, security boundaries, and scope.
3. **Check memory for amplifiers.** Standing entries such as "always run all review axes" or "never done until offline evidence passes" were generalized from one incident and force the router to its maximum. Replace them in the same pass as the skill edits, phrased as proportionality facts.
4. **Locate the source tree.** Skills are often stow symlinks; `readlink` a skill dir and edit the package source (for this user: `~/dotfiles/hermes/.hermes/skills/`), never the symlink target's copy.
5. **Put each fix in the skill that owns the behavior.** Router: sizing table (small / medium / large), promotion rules, default small, large only with explicit user agreement, and large routes straight to the multi-session planning skill (it already owns map, grilling tickets, and the spec hand-off; do not restate that route). Keep the router's table abstract and put worked sizing examples in a `references/sizing.md` the router points at: the user does not want concrete cases (a named comparison, a named fix) inside the router body. Include a "signals that do not raise the size" list (feels architectural, deserves an ADR, a tool could prove it, long issue thread). Spec skill: per-section budgets (word or bullet caps per section, total cap, "a section over budget means the work is oversized: say so"). Ticket skill: max tickets per spec (5) and max acceptance criteria per ticket (5, each an observable behavior; the user judged 8 too many). Testing skill: expected values come from an artifact written before the code (spec Testing Decisions, ticket acceptance criteria, or a user-confirmed "expected line" for small changes); proportion rules (one regression test per bug fix, one test per named behavior); no suite for tooling that does not ship; OWASP only with an exposed surface; strip TDD from the description if the eval forbids it. Implementation skill: for small changes fix the order expected line, user confirmation, failing regression test, then code, and record the confirmed line in the issue or commit message. Review skill: scope and frequency, see below. Verification principle: proof bounded by the cost of being wrong; an apparatus larger than the change is a separate user decision. Lever principle: when the lever outgrows the work, stop and ask.
6. **Keep phase skills task-only.** Remove "this is phase N of the cycle" prose from phase skills; only the router describes the route. Keep actionable dependency pointers (implementation keeps its pointer to the review skill; the review skill states the fixed point when closing a ticket).
7. **Remove skills the user names as overkill.** `git rm -r` the skill dir, delete its dead runtime symlink, then `search_files` the whole package for its name and glob pointers and rewrite every dependent step; renumber procedure lists after deleting a step.
8. **Update the eval contract** (see Eval contract) and rerun the gates before reporting.
9. **Report** as a change-per-skill list plus the measured numbers that motivated each, then offer the repo cleanup as a separate step. When the user accepts, follow [`references/apparatus-retirement.md`](references/apparatus-retirement.md).

## Review Frequency Rule

When the user asks whether reviews should be cut, fix frequency and scope, not the axes: the axes catch different defects. Small change: inline review by the agent, no sub-agents. Medium or large: full review once per unit of work after the last ticket lands and the suite is green, not per ticket. After fixes: re-run only the axis that produced the finding with a narrowed brief. Two full rounds without convergence: stop and show remaining findings. Verification scripts and evidence are out of the review target unless asked.

## Eval Contract

The dev-cycle library is pinned by `eval/references/dev-cycle-scenarios.json` whose SHA-256 is embedded in `eval/scripts/run_dev_cycle_behavior.py` as `EXPECTED_MATRIX_SHA256`.

1. Run `terminal(command="python3 hermes/.hermes/skills/eval/scripts/validate_dev_cycle.py --baseline-ref HEAD --candidate-only")` from the dotfiles root; it fails on any `contains` needle you removed and on scenarios naming a deleted skill.
2. Edit the matrix: replace scenarios for removed capabilities with scenarios exercising the new behavior (e.g. a small error-handling change, a sync-versus-async comparison), keep `expected_scenario_count` exact, keep 2-space indent, update `optional_capabilities` and `optional_principles` for renamed ids.
3. Recompute the file's SHA-256 and write it into `EXPECTED_MATRIX_SHA256`.
4. Run each `eval/tests/test_*.py` directly with `python3 <file>`; `unittest discover` on that tree fails on import path.
5. Grep edited skills for em-dashes; the writing rules forbid them globally.

## Pitfalls

- Do not answer the user's "does this make sense?" with opinion; the measurements make the case and decide which skill to edit.
- "Default to building the lever" and "exhaust the design space" compose explosively without a cap: every proof becomes a tool, every tool gets tests and evidence. Cap them with proportionality wording rather than deleting them.
- Broad promotion triggers, not the phase skills, are usually the root cause; fix the router first, then budgets.
- When the user asks whether the new rules guarantee tests are written against the spec rather than the code, answer honestly: budgets alone do not; only a pre-code artifact holding the expected values does. The small-size route is where the gap opens, because it skips the spec; close it with the expected line rule before claiming the guarantee.
- Edit source files with the `patch` tool, one file or one coherent multi-file hunk at a time. A scripted regex rewrite over several source files through `execute_code` stalls on an approval prompt and leaves the tree half-edited.

## Verification

- Structural gate passes on all scenarios; unit tests pass.
- `search_files` for the removed skill names returns nothing outside git history.
- Memory no longer carries incident-derived "always maximal" rules.
- The user can point at each edit and name the measured symptom it addresses.
