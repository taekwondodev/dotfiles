---
name: interrogate
description: Challenge a design or diff with independent adversarial review.
disable-model-invocation: true
---

# Interrogate

Apply adversarial pressure to a design, implementation, or diff. Look for blind spots, missing requirements, unsafe assumptions, and tests that do not prove the claim.

## Procedure

1. Read the source material, applicable principles, `coding-standards`, `architect`, `testing`, and the spec when available.
2. When the change warrants independent review, launch separate subagents through the available delegation capability.
3. Give each reviewer self-contained context and a distinct risk area, and prevent scope expansion by default. If delegation is unavailable, label any single-context review as such and do not claim independent coverage.
4. Inspect the evidence and diff yourself.
5. Categorize findings as act on, consider, noted, or dismissed, with reasons.
6. Return findings to `code-review` or `architect` without merging separate review axes into one score.

## Verification

Each finding cites a file, hunk, requirement, or observable behavior. Hard violations are separated from judgment calls. Delegate summaries are checked against artifacts.
