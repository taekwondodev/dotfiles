---
name: prototype
description: Build disposable alternatives to settle a technical or behavioral fork.
disable-model-invocation: true
---

# Prototype

Use a small disposable experiment when observation can resolve a technical or behavioral fork faster than discussion. A prototype informs a decision. It does not decide product scope or user preference.

## Procedure

1. State the question and the observation that would distinguish the candidates.
2. Define the smallest useful input, output, and verification check.
3. Build structurally distinct alternatives when the choice is architectural.
4. Run the same comparison against every candidate.
5. Record behavior, complexity, failure modes, and measurements.
6. Return the evidence to `grilling` or `architect` without silently retaining prototype code.

## Verification

The prototype is disposable or its retained scope is explicit. Every candidate ran against the same check. The result states what was learned and what remains undecided.
