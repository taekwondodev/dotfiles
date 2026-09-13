---
name: principle-fix-root-causes
description: "Apply when debugging. Trace each symptom to its root cause and fix it there; reproduce first, ask why until you reach it, resist nil-check guards that silence crashes."
disable-model-invocation: true
---

# Fix Root Causes

When debugging, trace every problem to its root cause and fix it there.

**Why:** Symptom fixes accumulate. Each workaround makes the system harder to reason about, and the real bug remains. Root-cause fixes are slower upfront but reduce total debugging time.

**Pattern:**
- Reproduce first.
- Ask "why" until you hit the root cause
- Resist the urge to add guards (adding a nil check to silence a crash is a symptom fix)
- If a workaround needs a paragraph-long comment to justify it, the code is wrong (fix the code, not the comment)
- Check for the pattern, not just the instance (grep for the same pattern, fix all instances)
- When stuck, instrument. Don't guess (add logging, read the actual error)

**Restart bugs: suspect state before code**

When something "fails after restart," suspect stale persistent state first: config files, caches, lock files, serialized state. If clearing a state file restores behavior, prioritize state validation as the fix.

## Recheck the premise after repeated failures

When two or more fixes assume the same premise and fail the same check, test the premise before attempting another fix.

1. Write the shared premise and the failed check explicitly.
2. Identify an observation that would distinguish that premise from an alternative explanation. Use the smallest probe that can make the distinction. Compare actors or workloads only when the hypothesis concerns a difference between them.
3. Run the probe and record whether the result supports, contradicts, or leaves the premise unresolved. An inconclusive result does not rule out the premise.
4. Revise the hypothesis or the probe before the next fix. Keep product and scope changes subject to the user's decision.

Completion criterion: the premise, observation, result, and reason for the next attempt are recorded. Another implementation based on the same untested premise is not progress.