---
name: macos-runtime-profiling
description: "Use when profiling resident CPU and memory for macOS apps."
version: 1.0.0
metadata:
  hermes:
    tags: [macOS, Swift, performance, profiling, Release, SwiftUI]
---

# macOS Runtime Profiling

Use this skill for a native macOS application's resident CPU/memory profile, especially when the result must be a committed baseline and a shareable report.

## Procedure

1. Read the app's domain context, applicable performance ADRs, build/install skill, and verification skill before changing code. Preserve the app's existing bounded context; runtime profiling observes the process and must not enter provider, quota, accounting, or credential domains.
2. Define the measurement contract before implementation: offline harness or installed Release artifact, authorized execution boundary, OS metric names, sampling cadence, state labels, coverage threshold, payload schema, provenance, accounting semantics, equivalence/selection rules, and rebaseline policy. Treat changes to these as an ADR-level contract change. Before comparative runs, trace the harness entry point through its actual dependencies and workload; a candidate executable hash proves identity, not that the differing candidate path was exercised. Treat passed gates from an inconclusive earlier experiment as readiness evidence only, never as candidate selection. Apply the comparative preflight in `references/process-metrics.md` before freezing the apparatus.
3. Put the OS boundary in one injected reader. Read physical footprint through task VM information and process CPU time through task thread-time information; compute CPU percentage from consecutive CPU-time and monotonic-time deltas. Keep aggregation, coverage validation, and payload shaping pure and testable.
4. Start the profiler only after a direct environment-variable gate succeeds. On the inactive path use `getenv` directly and return before materializing the environment dictionary, reading a clock, allocating a destination URL, querying task information, creating a task, or performing file I/O.
5. Reuse the existing lifecycle signal for state tagging. For a SwiftUI popover, consume its existing `onAppear`/`onDisappear` callbacks rather than adding programmatic open/close control or a second visibility mechanism.
6. Make a session valid only when every required state independently meets the coverage threshold. Aggregate memory average/peak and CPU mean per state from the injected stream; test the exact threshold and just-below boundary with literal expected values.
7. Write the session payload atomically during the synchronous shutdown path. Do not dispatch the final write and immediately terminate the process, because termination can race the asynchronous write. Write invalid sessions for diagnosis if useful, but make the measurement tool reject them and never record them as a baseline.
8. Separate non-live preparation from runtime consent. Build each clean, source-bound candidate once and retain its source closure and executable digest without installing or launching it. Within an explicitly authorized installed-artifact campaign, serialize around one owned app and hardware writer; install and launch only the retained executable, require exactly one executable-path process, give the operator explicit state instructions, capture parent-monotonic phase boundaries, and hash the executable before and after the run. Require session-scoped consent for each invasive category, with stress and sleep/wake authorized separately. For offline-only work, execute only the inspected non-invasive harness and label its costs as offline; leave installed-app attribution unproven. Record only aggregates plus machine/OS/architecture/executable provenance in the committed baseline; exclude the sample series and all app-domain data.
9. Generate the report asset from the committed launch and resource baselines with a self-contained renderer unless a dependency is justified and pinned. Make the renderer fail when a required baseline is absent; never invent measurement values to make a chart render. If Swift and a script exchange JSON, verify the actual encoded shape at that boundary; use explicit `Codable` structs for object-shaped maps rather than enum-keyed dictionaries whose encoding can become an alternating array.
10. Verify in order: focused domain tests, full `make test`, Python syntax checks, and `make check`. Run `make build`, `make verify`, and the real manual profile/chart generation only when installation and live execution are authorized; an offline measurement task does not authorize them. Keep the real Release baseline and generated chart in sync, then run the fixed-point code review before commit.

## Always-on pitfalls

- Prefer a Release-instrumented binary over a Debug-only sampler because optimization and runtime behavior otherwise differ.
- Do not use RSS when the contract names Activity Monitor's physical footprint; the two metrics answer different questions.
- Do not assign the entire interval after a popover transition to the wrong state; define and test the interval ownership explicitly.
- Do not average derived CPU percentages by recomputing from aggregate totals unless the contract calls for time weighting; the stated sample mean and the weighted process utilization are different metrics.
- Do not let the baseline carry raw samples, environment contents, provider responses, credentials, or Hermes runtime data; provenance and aggregates are sufficient for the report and reduce disclosure risk.
- Do not claim the profiling feature is complete from compilation alone; a committed baseline and chart require a real session on the installed artifact, while operator-controlled physical input, permissions, stress, and sleep/wake cannot be replaced by a fixture.
- Before a consented system-input campaign, prepare a keyboard-accessible emergency stop that revalidates the exact owned process before signalling; never substitute a watchdog, synthesized system input, automatic permission mutation, or automatic relaunch.

## References

- See `references/process-metrics.md` for the OS reader, state-coverage, shutdown, and baseline-schema decisions.
