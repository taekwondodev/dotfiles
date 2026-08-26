---
name: runtime-forensics
description: Diagnose a live runtime symptom from captured signals and source mapping.
disable-model-invocation: true
---

# Runtime Forensics

Diagnose a live symptom through real runtime instrumentation. Use for leaks, idle CPU spin, intermittent glitches, unexpected scheduling, and similar behavior. The default deliverable is a diagnosis, not a fix.

## Procedure

1. Capture the matching live signal on the real surface.
2. Reduce the artifact to the smoking gun: hot path, retainer chain, or unexpected loop.
3. Confirm the mechanism with focused instrumentation where possible.
4. Map the finding to source file, symbol, and line.
5. Return the diagnosis to `grilling`, then route to `perf-issue` or bug-fix if a fix is requested.

## Verification

The signal and artifact path are recorded. The mechanism is confirmed or marked as the strongest supported hypothesis. The source mapping is explicit. No fix is silently applied.
