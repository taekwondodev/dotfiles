---
name: blast-radius
description: Find what a change could break beyond the immediate diff.
disable-model-invocation: true
---

# Blast Radius

Find dependencies and behavior outside the obvious diff before a change ships. Prove safety with repository searches and real checks rather than assertions.

## Procedure

1. Identify the changed symbol, contract, data shape, or behavior.
2. Search all callers, implementers, serializers, migrations, fixtures, docs, and external boundaries.
3. Classify each affected consumer and likely failure mode.
4. Run the smallest check that proves the important safety assumption.
5. Return the findings to `to-spec`, `implement`, or `code-review`.

## Verification

Every claimed consumer is found through an actual search. Important assumptions have a check or are marked unproven. The result distinguishes confirmed impact from plausible risk.
