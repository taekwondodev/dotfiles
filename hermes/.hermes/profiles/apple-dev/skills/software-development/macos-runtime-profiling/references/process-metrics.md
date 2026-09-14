# Process metrics and baseline recipe

## Comparative preflight

1. Inspect the manifest, harness entry point, and caller-to-effect path before accepting prior passing reports. Identify which candidate-specific adapter, consumer, and lifecycle paths actually execute; linking only shared Domain/Service code cannot compare unexecuted Handler topologies.
2. Compare both candidate diffs from their common base manually. Separate the intended experimental variable from policy, capacity, instrumentation, and workload drift. When shared policy differs, run one source-bound Domain probe against both revisions and add same-candidate controls; record source hashes, compiler flags, executable bindings, raw observations, and exit status. Equal controls validate the probe's consistency, not the desired policy or native reachability.
3. Check the clock implementation, not only its field name or monotonicity. Fixed-increment fixture counters belong to logical scenario evidence; retain their historical meaning and exclude them from measured latency distributions.
4. Require observed workload phase boundaries for each resource window. Parent process start time and labels such as idle, burst, or suspended do not prove the child entered those states. Reject resource attribution when the sampled workload is unrelated arithmetic or sleep rather than the claimed input, consumer, or lifecycle activity.
5. Preserve raw resource samples and failed/censored sampling attempts in local evidence, then reconstruct counts, windows, summaries, and retention from them. Keep committed baselines sanitized and aggregate-only. A structurally valid summary cannot replace its missing raw observations.
6. Measure instrumentation overhead while the same relevant event path executes in both enabled and disabled runs; records emitted only before an unrelated workload do not establish event-path overhead.
7. Freeze configuration, alternating run order, normal-use versus stress workloads, and repeatability/equivalence criteria only after the correctness and apparatus gates pass. Report a failed gate as blocked comparison, not as a winning topology or completed delivery. A differing Domain result establishes drift; settling an ambiguous shared policy remains a separate decision.

## Consented installed A/B campaigns

1. Freeze candidate refs, build/sign/launch path, alternating order, physical workload, phase durations, environment gates, missing-data policy, accounting interpretation, equivalence rule, and selection rule before observing either candidate.
2. Keep preparation non-live: validate clean pinned worktrees, build each Release candidate once, retain the complete source closure and executable, and compile any environment probe without installing or launching the app.
3. At collection time, require explicit session consent for installation/launch, physical input or hardware writes, normal UI activity, permission changes, stress, and sleep/wake. Keep stress and sleep/wake independently authorized; never persist consent across sessions.
4. Hold one campaign lock for the entire run. Before switching candidates, stop the exact installed executable, prove zero owners, install the retained candidate, verify the installed hash, and require exactly one live process. Never rebuild during measured collection.
5. Start lifecycle capture before launch, filter evidence to the verified PID, reject log-loss markers and sequence gaps, and preserve raw logs. Sample the same PID with `proc_pid_rusage`; retain failed and censored polls and exclude them from numeric summaries rather than imputing values.
6. Use physical operator input and record parent-monotonic phase boundaries. Full instrumentation should bind callback/lifecycle records and app timing to the same executable; inactive runs should avoid detailed event recording and exist to quantify overhead. Report normal use, stress, and instrumentation overhead separately.
7. Reconcile every run internally. Do not require exact cross-candidate admission counts when topologies legitimately differ; predeclare which rejected, overflowed, or stale work is a normal-use correctness failure, and never let a faster surviving subset compensate for lost work.
8. Request a normal app quit after a successful run, use exact-process cleanup on failure, and keep a keyboard-accessible emergency stop prepared. Do not use synthesized system input, automatic permission changes, watchdogs, or automatic relaunch.
9. Retain raw local evidence, but publish a projection that removes local paths, process identifiers, and personal host details. Failed, missing, naturally unavailable, or unexercised scenarios remain explicit; do not add replacement runs or reinterpret rules after observation.

## OS reader

- In-process: query `TASK_VM_INFO` and use `phys_footprint` for the Activity Monitor-style memory metric; query `TASK_THREAD_TIMES_INFO` for cumulative user and system CPU time.
- External idle of the installed app: `proc_pid_rusage` on the verified exact-path PID; `ri_phys_footprint` is the Activity Monitor quantity; `ri_user_time` and `ri_system_time` are Mach absolute-time ticks. Convert with `mach_timebase_info` before forming a percent. Refuse to measure when that installed executable is not the live process.
- Sample with a monotonic awake-time clock. For consecutive samples, convert CPU ticks to seconds, then compute `deltaCPU / deltaWallTime * 100`; clamp negative values caused by clock or counter anomalies to zero.
- Treat the first CPU sample as a zero-delta sample, or exclude it consistently from the contract; do not let an unpaired sample create a spike. Prove the pairing rule with a fixture of consecutive already-converted seconds, not with a live process and not with a nanosecond pretence.
- Format idle CPU on the committed chart with enough fractional digits that a sub-0.1% measurement is still visible. Two decimal places turn 0.035% into 0.00% and hide regressions.

## State coverage

- Store each sample's state, metrics, and owned interval duration.
- Sum durations independently by state. Validate `duration >= threshold` for every required state, including the exact boundary.
- Keep the raw series in the transient session payload only; the committed baseline contains aggregates and provenance.

## Shutdown and provenance

- Cancel the sampler, compute the result, encode it, and atomically write it before invoking application termination.
- Let the harness reject invalid coverage and avoid recording it as a baseline.
- Hash the installed executable before and after the run; a changed artifact invalidates the measurement.
- Include only machine model, OS, architecture, executable hash, schema/contract version, and per-state aggregates in the baseline.

## Cross-language payload and report generation

- Test the serialized payload as the consumer sees it, not only with a producer-side encode assertion. Swift `Codable` dictionaries keyed by enums may serialize as alternating key/value arrays; use explicit `Codable` structs when the JSON contract requires an object and assert that shape in a producer-consumer test.
- Read both launch and resource baselines; fail on missing or malformed inputs with a concise boundary error.
- Render one deterministic chart (SVG or PNG) from those files, include the product's actual identity motif/palette rather than an assumed substitute, and inspect its labels and existence before replacing the README asset.
- Regenerate the image in the same change as a rebaseline so text, bars, and data cannot drift.
