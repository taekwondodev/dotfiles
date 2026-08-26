---
name: interrogate
description: Challenge a design or diff with independent adversarial review.
disable-model-invocation: true
---

# Interrogate

Apply adversarial pressure to a design, implementation, or diff. Look for blind spots, missing requirements, unsafe assumptions, and tests that do not prove the claim.

## Procedure

1. Read the source material, applicable principles, `coding-standards`, `architect`, `testing`, and the spec when available.
2. Dispatch independent review angles with `delegate_task` when the change warrants it.
3. Ask each reviewer to challenge a distinct risk area without proposing scope expansion by default.
4. Inspect the evidence and diff yourself.
5. Categorize findings as act on, consider, noted, or dismissed, with reasons.
6. Return findings to `code-review` or `architect` without merging separate review axes into one score.

## Verification

Each finding cites a file, hunk, requirement, or observable behavior. Hard violations are separated from judgment calls. Delegate summaries are checked against artifacts.
