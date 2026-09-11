# Sizing examples

Reference for the `Size the work` step in `dev-cycle`. Each example names the signal that decides the size and the ceremony that size buys. Read it when the table alone does not settle the size.

## Small

- **Changing how one error is handled** (retry becomes suspend, a failure becomes a logged pass-through). Signal: one behavior, reversible, nothing persisted. Route: reproduce, expected line confirmed by the user, regression test, change, existing suite and build, the user tries it once, inline review.
- **Moving work between threads, actors, or queues inside one application.** Signal: internal ownership only, no consumer outside the process. Route: same as above. Record the choice in an ADR when it is durable; an ADR is not a spec.
- **Adjusting a threshold, timeout, or label.** Signal: one value, one file.

## Medium

- **Comparing two implementations of the same behavior** (synchronous versus asynchronous handling, main run loop versus dedicated thread). Signal: an architectural fork with no persisted or external contract. Route: `prototype` both, drive them with the same check, let the user try both, record the verdict in the issue. Two builds and one log line are the proof; a measurement campaign is not.
- **One feature touching a few modules** (a new panel control wired through handler and service). Signal: several layers, one bounded context. Route: `grilling` on the open decisions, `to-spec` in the existing issue, implement, `code-review` once.
- **Changing a contract other code in the same repository depends on.** Signal: callers to migrate, all visible. Route: medium plus `blast-radius`.

## Large

- **A new bounded context or a persisted format change.** Signal: data on disk or a schema that outlives the process.
- **A security or trust boundary** (permission model, signing, sandbox).
- **Work that will not fit one session by construction** (a port, a redesign of the product's shape). Route: `wayfinder`, with the user's explicit agreement first.

## Signals that do not raise the size

- The change feels architecturally important.
- The change would benefit from a diagram or an ADR.
- A verification tool could be built to prove it. The tool is a separate decision, made by the user.
- The issue tracker already has a long discussion. Length of discussion is not size of change.
