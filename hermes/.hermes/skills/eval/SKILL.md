---
name: eval
description: Evaluate skill routing and behavior against a fixed scenario matrix.
disable-model-invocation: true
---

# Eval

Test whether a skill, router, or workflow change produces the intended agent behavior. Compare against a fixed scenario matrix rather than relying on one successful transcript.

## Procedure

1. Define scenarios, expected route, applicable principles, required gates, and completion criteria.
2. Run the same scenarios against the baseline and the candidate behavior where possible.
3. Record selected skills, questions, decisions, tool actions, verification, and failures.
4. Check source-of-truth boundaries and unwanted scope or ceremony.
5. Report regressions, improvements, and unresolved cases. Do not silently promote a candidate based on one example.

## Dev-cycle contract

`references/dev-cycle-scenarios.json` is the fixed 16-scenario contract for the integrated development workflow.

- `scripts/validate_dev_cycle.py` is the structural gate. It checks required workflow text, skill isolation, skill existence, and reference links against a git baseline and the working tree. It does not prove model routing behavior.
- `scripts/run_dev_cycle_behavior.py` is the routing-decision oracle. Fresh Hermes processes predict the complete route for the same scenario prompts with each unique baseline or candidate policy bundle. Identical policy hashes share one fresh decision and the candidate is recorded as an alias, preventing a no-op comparison from becoming a sampling regression. Shared failures remain comparative evidence but do not block an unchanged candidate; failures from a fresh candidate policy remain blocking. The model prompt is variant-neutral; baseline and candidate attribution is recorded in report metadata. The runner records modes, allowed capabilities and principles, checkpoints, questions before evidence, testing methods, architecture styles, review axes, and structured verification intentions. It rejects unknown, forbidden, and scenario-unexpected skills, validates every declared route field strictly so malformed output is a deterministic failure, and records hashes for the runner, matrix, and policy bundles. The matrix itself is an immutable contract: the runner fails the run if the candidate scenario matrix no longer matches an embedded SHA-256. It does not execute the routed tools or slash-command dispatcher, so it is not an end-to-end execution gate.

Run the structural gate with `terminal(command="python3 hermes/.hermes/skills/eval/scripts/validate_dev_cycle.py --baseline-ref HEAD")`. Run the behavioral gate with `terminal(command="python3 hermes/.hermes/skills/eval/scripts/run_dev_cycle_behavior.py --baseline-ref HEAD")`. A baseline or shared-policy failure is comparative evidence; any failure from a fresh candidate policy is a blocking regression.

## Coding-standards contract

`references/coding-standards-scenarios.json` fixes the behavior contract for cognitive complexity, validated types, contextual rules, trusted internal values, established facts, and architecture-neutral input handling. `scripts/run_coding_standards_behavior.py` compares `coding-standards/SKILL.md` at the git baseline and in the working tree, rejects malformed decisions, and embeds the immutable matrix hash. Run it with `terminal(command="python3 hermes/.hermes/skills/eval/scripts/run_coding_standards_behavior.py --baseline-ref HEAD")` whenever coding philosophy or validation behavior changes.

## Verification

Every unique policy bundle has a fresh model decision with attributable policy and matrix hashes; identical bundles are explicitly aliased rather than sampled twice. The matrix includes edge cases and direct-invocation prompts, but does not exercise Hermes's slash-command dispatcher. Results distinguish structural policy failures from routing-decision failures. Run each routed procedure's artifact verification separately.
