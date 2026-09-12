# Instrumented comparison campaigns

Read only when the user has explicitly asked for a measured A/B comparison of tap topologies after a manual comparison on the installed app was inconclusive. A campaign is a project of its own; its code, tests, and evidence must stay smaller than the change it measures or the user must agree to the larger scope.

## Candidate executables

- Use an opt-in Release executable that compiles each candidate's real bridge sources and enters through the real post-parse candidate seam. A common harness that drives only shared Domain/Service code erases the scheduling variable being compared.
- Keep framework-free scenario and workload files byte-identical; confine topology adaptation to candidate-local bindings; emit topology labels only after identities are observed inside the owner-thread seam. Hard-coded names are not proof.
- Freeze production-equivalent admission capacity and label phases (normal use, stress, held consumer, lifecycle, cleanup) explicitly.
- Make the outer runner compare correctness output against a spec-derived literal matrix so the artifact cannot self-grade.

## Clocks and attribution

- Never compare absolute monotonic ticks produced by different processes or runtime APIs; epochs and conversions differ. Stream child boundary identities with child-local timestamps, stamp each complete record when the parent observes it, and attribute parent resource samples only on the parent clock.
- Reject a nominally populated phase with zero attributed samples; validator and summarizer can otherwise agree on the same broken clock assumption.
- Parse an append-only boundary sidecar only through its last newline and retry an incomplete tail on the next poll.

## Gates before collection

- Separate `gate`, same-candidate `control`, and cross-candidate collection. Permit A/B only after A/A and B/B fingerprints (timestamps and resource noise excluded) are green for every candidate × workload × instrumentation cell.
- Bind candidate ref, exact source closure, driver digest, frozen configuration, compiler flags, executable path and hash. Keep run ordinal out of the configuration digest.
- Freeze a machine-readable protocol before the first cross-candidate observation: bindings, workloads, instrumentation modes, warmups, run counts, counterbalanced order, sample minima, summary definitions, missing-data rules, equivalence and selection rules, environment invariants, retention, stop conditions. For every accounting field predeclare whether it is a within-run conservation invariant, a cross-candidate equality gate, or a ranked outcome.
- Validate conservation identities (attempted = admitted + rejected; admitted = completed + discarded + pending) over one event universe: unmatched key-up pass-through belongs to pairing, not admission rejection.
- Define the repeatability statistic with its minimum valid runs; a small-sample nearest-rank p95 collapses to the maximum and inflates the equivalence band.
- Bind the protocol digest into configuration, report, and manifest; retain the protocol file beside the evidence; pin tool and matrix digests before preparation and re-check before and after each run.
- Materialize every native proof limit as a machine-readable report entry validated against a spec-derived literal list.
- In mutation tests, deep-copy mutable oracle collections into fixtures; aliasing produces a false pass.

## Running and analysis

- Give every subprocess layer its own watchdog. Run outer commands in a new process group that includes candidate children; terminate the group, wait the grace period, then kill survivors. Prove both watchdogs with harmless sleepers that ignore `SIGTERM` and leave descendants behind.
- A complete frozen campaign may deliberately exit nonzero for a predeclared `inconclusive`; read stderr and campaign state before interpreting. Never tune workload, equality rules, or selection after seeing the result.
- Revalidate each selected report against its digest, identity, bindings, child status, literal contract, raw reconstruction, and fingerprint before computing metrics; campaign-level digests alone let a changed report influence the result.
- After any byte change to runner, matrix, protocol, driver, or candidate source, create fresh gate evidence. Evidence directories are caller-selected, new, and never cleared.
- For a dirty worktree bound by revision, `git stash create` yields a dangling snapshot without moving refs, only when every required source is tracked.

## Retiring a campaign

When the manual comparison settles the question, remove the campaign in one commit and carry only the verdict and the open defect forward.

- Stop every candidate process before deleting its bundle (`pgrep -fl` first); deleting a running `.app` leaves an orphan holding the executable and no bundle to quit from.
- Remove in dependency order: evidence store, project `verify-*` skill, campaign scripts and their tests, Makefile targets, `Package.swift` harness and probe targets, then the in-app instrumentation (recorders, measured repository wrappers, measurement IDs on domain requests). Grep `Sources` and `Tests` for each removed symbol after every step; a test that imports a deleted script (or a deleted assessment type) fails only at `make check`, not at `swift build`.
- Command-surface and `check` scripts enumerate files and targets by literal path; update those lists in the same change or the check fails on a missing file it was told to parse.
- Remove git worktrees (`git worktree remove --force`, then `prune`) before deleting the branches they hold, then delete candidate branches locally and on the remote.
- Write one ADR with: what was compared, what the user observed, which topology stays and why, what was removed, and the open defect with facts, working hypothesis, and its size. Close the campaign issues with a two-line verdict pointing at the ADR and open one small issue for the defect that carries the expected line.
- Verify the production command surface after the cut: `make test`, `make check`, `make build`, `make verify`, and confirm only the production bundle remains installed.

## Installed two-identity runs

- Install each candidate under its own bundle identifier, name, and path so Accessibility grants are per identity and never rely on ad-hoc cdhash grants surviving binary replacement.
- Require a candidate-bound readiness record (bundle id, executable hash, source ref, trust, tap ownership) before each launch; stop every other known identity first; stop the launched candidate on every exit path.
- Cleanup removes only candidate bundles and verifies production is untouched.
- Budget lifecycle diagnostic records generously when acknowledgements are relayed through chat; a small fixed record budget exhausts during operator delays and fails the run for the wrong reason.
