# Structured lifecycle observability

Use when you must diagnose a live subsystem (event tap, permission lifecycle, always-on agent) WITHOUT changing its production behavior. The deliverable is discriminating evidence, not a fix.

## Preserve while observing

- Record only what the code already computes. Do not add OS permission or event-tap API call sites just for logging; a source-level callsite count before/after is cheap proof the control surface is unchanged.
- Keep the OS control calls, event mask, teardown order, and callback return values byte-for-byte; append only observation statements and a diagnostic reason parameter.
- Copy the exact pre-change sources to a `*-before/` mirror before editing so a later diff isolates your delta from a pre-existing dirty tree spanning many unrelated files.

## Make observability opt-in and bounded

- Gate capture on a process-local flag (a launch argument), never a persisted preference or global environment. Disabled mode must create no recorder, queue, timer, or logging history and perform no extra OS query.
- Emit typed fixed-field events with begin/end operation tokens from a closed enum, never free-form strings or user-event payloads (no key codes, positions, window titles, paths).
- Set a finite record budget followed by exactly one exhaustion marker. Exhaustion seals diagnostic emission only; it must never change interception, recovery, branching, or callback results.
- Gate lifecycle markers on real resources. A per-second poll that emits an empty "stop" marker burns the whole budget during the exact prolonged-degraded window you are capturing; emit a marker only when an object actually exists to act on.

## Interpret honestly

- A marker begin-without-end identifies a candidate last operation; it does not prove a hang. Process death, log loss, or budget exhaustion also truncate traces. An external stack sample of the exact process is the complementary discriminator because it does not depend on the app's main loop.
- A structurally complete trace, a clean empty teardown, or repeated disable/create pairs each supports only the narrow claim it names, never "global input recovered" or "macOS released internal state". Query returns (including false) are observations, not outcomes; "service scheduled" is not "service applied".
- Classify incomplete vs deadlocked in a pure assessment over typed records, keeping the logging backend and event-tap Handler out of unit tests.

## Safety gate for disruptive experiments

Before any permission change, relaunch, or capture that can disrupt system input, obtain separate consent for (1) static investigation, (2) diagnostic edits plus offline checks, and (3) any runtime retry. Agree a keyboard-accessible termination plan first and prioritize restoring input over collecting evidence. A diagnostic build is not permission to reproduce.
