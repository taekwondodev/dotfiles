---
name: trace-forensics
description: Diagnose a supplied profile, trace, heap snapshot, or spindump.
disable-model-invocation: true
---

# Trace Forensics

Diagnose a problem from an existing profiling or tracing artifact. Read the supplied dataset instead of substituting a fresh run. Use for CPU profiles, traces, heap snapshots, and spindumps.

## Procedure

1. Identify the format and load it with the appropriate tool.
2. Transform large data into a queryable shape before reading it deeply.
3. Narrow to hot frames, retainer chains, blocked threads, or the relevant event path.
4. Attribute the finding to source file, symbol, and line.
5. Compare a paired capture when available.
6. State whether the result is confirmed or only the strongest artifact-supported hypothesis.
7. Return the diagnosis to `grilling`, then route to `perf-issue` or bug-fix if a fix is requested.

## Verification

The original artifact, reduced finding, source mapping, and confidence level are recorded. No claim is based on a proxy or an unexamined self-report.
