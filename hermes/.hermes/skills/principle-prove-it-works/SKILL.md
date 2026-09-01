---
name: principle-prove-it-works
description: "Apply after completing a task, before declaring done. Verify against the real artifact (run the feature, read the actual value, inspect the diff), not a proxy, self-report, or 'it compiles.'"
disable-model-invocation: true
---

# Prove It Works

Verify every task output by checking the real thing directly. Do not infer from proxies, self-reports, or "it compiles."

**Why:** Unverified work has unknown correctness. Indirect verification (file mtimes, output freshness, agent self-reports, cached screenshots) feels cheaper than direct observation. Acting on a wrong inference costs far more than checking the source.

**Pattern:** After completing any task, ask: "how do I prove this actually works?"

Check the real thing, not a proxy:
- Check process liveness directly, not indirectly through derived state
- Read the actual value, not a cached or derived representation
- When verification fails, suspect the observation method before suspecting the system

Code and features:
1. Build it (necessary but not sufficient)
2. Run it and exercise the actual feature path
3. Check the full chain: does data flow from input to output?
4. For integrations, test the full communication path end-to-end

Delegation: trust artifacts, not self-reports.
When verifying delegated work, inspect the actual output artifact (git diff, file contents, runtime behavior), not the delegate's summary. Agents report what they intended, not always what happened.

## Project verification skills

When a claim depends on public runtime behavior, inspect the project skill index for an applicable `verify-*` skill before designing a one-off check. Load it when its named surface covers the behavior and its isolation contract makes the drive safe.

Use the verification skill for:

- a read-only runtime observation on an isolated or non-mutating path;
- a bug reproduction before the fix and the same drive after it;
- acceptance of new public behavior;
- before-and-after equivalence for a runtime-sensitive refactoring;
- a representative workload when a performance procedure owns the metric and measurement method;
- the smallest live check selected by blast-radius analysis;
- independent review of runtime evidence when rerunning the drive is affordable.

Prefer a more direct proof for static artifacts, documentation, compile-time guarantees, internal properties covered by deterministic tests, or behavior outside the skill's mapped surface. A verification skill complements tests; it does not replace the smallest regression proof.

Follow the selected skill's `Doctor`, isolation, drive, evidence, and cleanup contracts. Use the same drive for baseline and result. When the skill cannot cover the claim, record the coverage gap and use another check rather than treating an internal shortcut as public proof.

## Script the check when you can

The strongest proof is a deterministic script that re-runs the same comparison, not a one-time eyeball. Write the script, run it, and keep its output as an artifact a reviewer can re-run instead of trusting your word. A script comparing the old and new compiled output catches what a glance misses.

Keep the artifact visible for the human. Commit it only for large or complex work where the trail has to be auditable later, like a big port or migration (the **show-me-your-work** skill). Most work just needs it visible, not committed.