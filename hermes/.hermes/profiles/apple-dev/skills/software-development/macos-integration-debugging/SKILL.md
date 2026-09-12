---
name: macos-integration-debugging
description: "Use when debugging macOS integrations, permissions, login items, or local agents. Verify the real producer and OS-owned contract."
---

# macOS Integration Debugging

Use this skill when a native macOS app integrates with a local CLI, profile system, database, or background agent and the UI shows missing, stale, or unavailable data.

## Core rule

Do not fix the presentation layer until the producer's real data contract is verified. A fixture or an invented JSON schema can make an adapter look complete while the running producer never writes that artifact.

## Workflow

1. **Capture the exact symptom.** Identify the UI state and the domain result behind it (`missing`, `unreadable`, `malformed`, `offline`, or `empty`). When native system feedback appears instead of an app-owned response, first distinguish pass-through from a rendering failure: verify the exact app process, then the required permission and control-eligibility gates. Process liveness and a valid signature do not prove interception permission.
2. **Resolve runtime configuration.** Check the effective environment variables, profile root, current user, and app sandbox/container assumptions exactly as the app does.
3. **Probe expected artifacts.** Check candidate paths for existence and type without printing credentials, tokens, cookies, prompts, or transcript contents. Record only safe metadata.
4. **Verify the producer.** Search the producer's source and official docs for the writer, schema, and lifecycle. Confirm that the producer actually creates the artifact on the target machine.
5. **Inspect an authoritative source.** Prefer, in order: a documented local export, a stable database schema, a runtime state/API used by the producer, or a CLI implementation. Do not assume an app's private JSON contract is real because the consumer can parse it.
6. **Trace each boundary.** Record what enters and exits Repository, Service, and Handler. Preserve error distinctions across boundaries: infrastructure errors stay inside the adapter; the Service maps them to domain-facing unavailable states; the UI renders those states explicitly.
7. **Build a red-capable probe.** Add a small deterministic test or script that reproduces the exact unavailable state and turns green only when the real source is read. Use secret-free fixtures for malformed/missing cases.
8. **Choose the smallest durable integration.** Reuse the producer's existing authentication and state when possible. Avoid separate provider logins, scraping, or copying secrets into the app. If no supported source exists, add a verified bridge rather than inventing a file contract.
9. **Verify lifecycle behavior.** For always-on menu bar apps, do not attach long-running refresh solely to a popover `.task`; own it in the app/model lifecycle. Use cancellation-aware async loops, one shared actor/service for manual and automatic refresh, and explicit stale/offline timestamps.
10. **Fence stale lifecycle results.** After an async permission, tap, or observer result returns, re-check its captured generation and current phase before suspending, publishing, or notifying. A late result must not overwrite a sleeping phase, because that can make wake handling ignore the sleep transition permanently.
11. **Defer termination for asynchronous cleanup.** When native teardown must finish before process exit, return `.terminateLater` from `applicationShouldTerminate(_:)`, perform cleanup without blocking the MainActor, and call `reply(toApplicationShouldTerminate: true)` only after the owner and dependent service have stopped. Do not rely on a fire-and-forget `applicationWillTerminate` task for ordering.
12. **Preserve process identity in OS-contract probes.** For TCC, event-tap, and login-item tests, launch the installed signed bundle through LaunchServices when the claim is about the app's own identity. A binary started as a terminal or agent subprocess is attributed to the responsible parent and returns a false grant: AXIsProcessTrusted reads true without a real authorization, the native Accessibility prompt never appears, and a mid-run revoke seems to do nothing, so the test falsely looks like a non-reproduction. Treat a missing native prompt as evidence the identity is not real, and confirm the prompt is actually asked when the grant claim matters. An `open` failure with a wrong bundle path is a path symptom, not an app result.
13. **Prove cleanup from a fresh process.** Stop every exact executable process, not only a shell wrapper, before resetting permissions or restoring a bundle. Treat a successful reset command as an attempted transition, then verify the resulting permission checks, login-item status, process count, and restored artifact.
14. **Separate event-tap ownership from delivery.** Keep CoreGraphics/CoreFoundation tap resources, their run-loop source, and callback context on one owner thread; cross the boundary with Sendable values and a bounded wake notification only. Keep FIFO order and stale-session rejection in the domain gate rather than creating a second work queue in the stream or callback; do not add a capacity that suspends the app, because the downstream Service already keeps only the latest desired state. Details in the `macos-event-tap-lifecycle` skill.
15. **Size the proof to the risk.** A rebuilt ad-hoc-signed bundle silently loses its Accessibility grant (the checkbox stays on, `AXIsProcessTrusted` returns false), so before any manual permission or tap test have the user toggle the grant off and on, reopen the app, and confirm one app-owned response; otherwise a negative result only proves no tap existed. For a personal utility the proof is `make test`, `make build`, one opt-in diagnostics run read from the unified log, and the user performing the sequence once; an offline harness, signed campaign bundles, or an evidence store is a separate decision the user makes explicitly.

For permission and login-item experiments, use `references/tcc-login-item-probes.md`.

## User-guided runtime acceptance

When a permission or event-tap experiment disrupts system input, restore input first, then stop and ask the user before relaunching or changing permissions. Give the user a short list of concrete actions with the expected result for each, one round at a time, and record only what the reply confirms. Distinguish subjective responsiveness from instrumented latency. For hardware controls, prefer a safe lower-boundary check over maximum output.

When the freeze is reproduced on every variant tried and the diagnostics log shows the process received no signal before the system disabled the tap, stop iterating: it is a platform limitation. Record the facts and the mitigation (quit the app before revoking) in an ADR and close the defect rather than building a measurement apparatus around it.

## Reconsider the integration point before repairing it

When the user questions why an integration intercepts a system-wide path, pause diagnosis-versus-mitigation choices and load `why`/`how`. Recover the original product requirement and explicit rationale from specs, ADRs, history, and current callers. Separate the capability needed for the experience from incidental choices such as callback work, run-loop placement, and recovery policy. Compare alternatives by which preserve the interaction and which change the product; assess whether the possible system-wide disruption is proportionate to the utility's purpose. Do not treat an implemented interception point as a settled requirement when the user has reopened it.

## Input-disruption safety gate

When an Accessibility or event-tap experiment disrupts system input, restore input first (agree a keyboard-accessible termination plan before any relaunch) and preserve the diagnostics trace. A diagnostic build is not a fix; tell the user what the next relaunch will test before doing it.

Parse the complete captured lifecycle trace before adopting an issue or handoff's causal summary. Check sequence continuity and diagnostic exhaustion, count creation/enable/teardown operations, and correlate them by resource identity; eligibility generations are not tap identities and advancing generations do not prove resource recreation. Check each disabled notification against the subsequent enabled-state query and actual operations, because a conditional recovery branch in source may never have executed. Correct a contradicted narrative explicitly rather than asking the user to choose which factual account to accept.

Treat paired teardown logs as evidence that app-side calls returned, not proof that global input recovered. Label empty teardown separately, identify tap creation attempts before treating them as live objects, and classify missing end markers as incomplete evidence until an independent signal distinguishes a hang from process death, log loss, or diagnostic exhaustion. Continued main-loop polling rules out a persistent stall only across the observed interval; it does not exclude transient callback stalls or establish WindowServer causality. Recovery after process termination implicates process-owned activity but does not identify the precise mechanism.

## Diagnostic continuity

When work spans sessions, keep one current checkpoint in the handoff: active task and user decisions, exact trace paths, process identity, completed and pending checks, and the next executable step. Record whether diagnostic capture is enabled and how to disable it. For a small fix that finishes in one session, the ADR and the issue's expected line are the record; do not maintain a handoff for it.

Treat intermittent native-feedback fallback as an unresolved trigger until evidence identifies why control eligibility was lost. Separate whether recovery and discarded input match the approved policy from whether rapid input should have caused the failure at all; a plausible recovery sequence is not proof that the trigger was legitimate.

For permission-sensitive opt-in capture on an existing installed artifact, follow `references/tcc-login-item-probes.md` before invoking a convenience measurement command.

## External-display audio control

When generalizing a monitor-volume utility, investigate identity and capability separately before changing targeting filters:

1. Trace both gates in source: how Core Audio recognizes the default output and how the DDC transport selects its physical recipient. Removing a model-name filter alone can route input for one display to another display's volume.
2. Inventory the connected displays and audio outputs with `system_profiler SPDisplaysDataType SPAudioDataType -json`; filter to relevant display/output names, manufacturer, transport, and default-output status before printing. Inspect display product attributes with `ioreg -a -l -w 0` parsed using Python `plistlib`. Traverse dictionary or list roots defensively, and emit only display-relevant fields; record serial presence rather than printing unique serials.
3. Require an unambiguous association from selected audio output to physical display to DDC endpoint, not a mandatory serial. Some displays omit the alphanumeric serial field; model and manufacturer can distinguish the current pair without proving a general association for identical models. A proxy's enumeration position is not itself proof of identity.
4. Separate discovery from compatibility: a DisplayPort audio output proves neither DDC volume support nor mute support. Inspect existing assumptions about returned volume ranges and mute values before calling the transport generic. After binding is established, probe capabilities without changing volume; validate any later hardware write reversibly against the actual recipient.
5. For this user's monitor utilities, follow the selected audio output only when the recipient is compatible and unambiguous. Treat volume and mute as independent capabilities: if only volume is supported, control volume and leave mute input to macOS. Do not simulate mute through zero volume unless requested, and do not promise that macOS can mute a passed-through device.
6. Report discovery, binding, capability reads, and end-to-end control as separate evidence levels. Successfully controlling one configured display while another is connected does not demonstrate control of both. Preserve unresolved capability checks as the next executable investigation step rather than closing feasibility after inventory alone.
7. Lead compatibility reports with a positive support contract and a short tested-device/capability table, not merely “not universal.” Define support by identifiable recipient, reachable DDC path, and verified volume read/write; name mute separately. Qualify evidence by monitor, connection, and host configuration, because an audio transport label does not guarantee a usable control channel. Keep current-topology feasibility separate from automatic output switching and any rebinding behavior actually in scope.
8. Honor explicit scope exclusions in both investigation and the resulting spec. When the user limits delivery to the current monitors and connections, omit hypothetical docks, adapters, indistinguishable models, and topology campaigns from acceptance requirements. Preserve the agreed no-wrong-recipient guard, but do not turn excluded configurations into blockers: bounded hardware support does not require universal certification. Record exclusions once instead of repeatedly warning about them.

For disposable Get VCP probes and reversible write/readback checks, follow `references/display-ddc-feasibility.md`.

## Required domain distinctions

At minimum, keep these states distinct where the source supports them:

- source missing;
- source unreadable;
- malformed or unsupported;
- valid but empty;
- live/persisted/stale;
- offline fallback.

Never convert all failures into an empty collection: that hides the root cause and makes the UI indistinguishable from zero usage.

## Security and observability

- Never log or display API keys, OAuth tokens, cookies, prompts, transcripts, or raw database rows.
- Add middleware-level observability for read outcomes and refresh availability, logging only safe categories/counts/status.
- Tests should cover malformed input, missing source, partial records, stale fallback, and cancellation where lifecycle work is involved.

## References

- `references/producer-contract-checklist.md` — compact checklist and command patterns for validating local producer contracts.
- `references/structured-lifecycle-observability.md` — opt-in, bounded instrumentation to diagnose a live subsystem without changing its behavior; how to preserve, gate, and interpret record traces.
- `references/unified-log-capture.md` — `log stream`/`log show` predicate capture of a running app's OSLog output, independent of the app main loop.
