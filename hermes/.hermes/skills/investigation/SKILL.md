---
name: investigation
description: Investigate an observable question with evidence before proposing changes.
disable-model-invocation: true
---

# Investigation

Answer a read-only question or reduce an unknown cause using inspected evidence. Do not modify project state or silently turn an investigation into an implementation.

## Procedure

1. State the question, scope, and current hypotheses.
2. Search and read the relevant repository, issue, documentation, or runtime sources.
3. Trace the mechanism from trigger to effect.
4. Load `principle-prove-it-works` when a material claim depends on public runtime behavior. Consume its project-verification selection and evidence contract.
5. Run a focused probe, test, or query when it can distinguish hypotheses.
6. Record evidence, rejected hypotheses, and unresolved uncertainty.
7. Return the result to `grilling` when it is part of a decision tree.

## Verification

Every material claim has an inspected source or reproducible observation. Facts, inferences, and hypotheses are clearly separated. No code or external state changed.
