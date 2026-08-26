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

## Verification

Every declared pass has observed evidence. The matrix includes edge cases and direct skill invocation. Results distinguish routing failures, procedure failures, and verification failures.
