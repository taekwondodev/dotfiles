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
14. **Separate event-tap ownership from delivery.** Keep CoreGraphics/CoreFoundation tap resources, their run-loop source, and callback context on one dedicated owner thread; cross the boundary with Sendable values and a bounded wake notification only. Keep FIFO order, capacity, overflow, and stale-session rejection in the domain gate rather than creating a second work queue in the stream or callback.
15. **Keep offline verification non-invasive.** When a common-contract harness is sufficient, snapshot the installed signed artifact's safe metadata/hashes and exact process identity before and after the run; build and execute only the isolated Release harness, and never install, launch, alter permissions, synthesize input, or touch hardware as part of that proof.

For permission and login-item experiments, use `references/tcc-login-item-probes.md`.

## User-guided runtime acceptance

After a permission or event-tap experiment disrupts system input, mark that acceptance gate failed and blocked. Preserve the stopped app and dirty tree; obtain an incident-path decision before relaunching or changing permissions. Static-investigation consent covers source and existing-evidence reads, not reproduction, instrumentation edits, installation, synthesized input, or hardware actions. Continue only individually approved manual gates, one at a time, updating the handoff after each. Earlier automated passes do not clear an OS-owned runtime failure.

Keep visual checks with the user and request a small group of concrete actions with an expected result for each. Record only the scenarios the reply confirms; a brief approval of a behavior list does not also answer a separate question about whether the app was restarted. Distinguish subjective responsiveness from instrumented latency. For hardware controls, prefer a safe lower-boundary check over maximum output, because the visual boundary behavior can be exercised without loud playback.

## Reconsider the integration point before repairing it

When the user questions why an integration intercepts a system-wide path, pause diagnosis-versus-mitigation choices and load `why`/`how`. Recover the original product requirement and explicit rationale from specs, ADRs, history, and current callers. Separate the capability needed for the experience from incidental choices such as callback work, run-loop placement, and recovery policy. Compare alternatives by which preserve the interaction and which change the product; assess whether the possible system-wide disruption is proportionate to the utility's purpose. Do not treat an implemented interception point as a settled requirement when the user has reopened it.

## Input-disruption safety gate

When an Accessibility or event-tap experiment disrupts system input, preserve the stopped-app state after recovery and mark the scenario failed and blocked. Obtain separate consent for static investigation, diagnostic edits/offline checks, and any later runtime retry. A diagnostic build is not a fix or permission to reproduce. Agree a keyboard-accessible termination plan before any relaunch; prioritize restoring input over capturing evidence.

Parse the complete captured lifecycle trace before adopting an issue or handoff's causal summary. Check sequence continuity and diagnostic exhaustion, count creation/enable/teardown operations, and correlate them by resource identity; eligibility generations are not tap identities and advancing generations do not prove resource recreation. Check each disabled notification against the subsequent enabled-state query and actual operations, because a conditional recovery branch in source may never have executed. Correct a contradicted narrative explicitly rather than asking the user to choose which factual account to accept.

Treat paired teardown logs as evidence that app-side calls returned, not proof that global input recovered. Label empty teardown separately, identify tap creation attempts before treating them as live objects, and classify missing end markers as incomplete evidence until an independent signal distinguishes a hang from process death, log loss, or diagnostic exhaustion. Continued main-loop polling rules out a persistent stall only across the observed interval; it does not exclude transient callback stalls or establish WindowServer causality. Recovery after process termination implicates process-owned activity but does not identify the precise mechanism.

## Diagnostic continuity

Update the authoritative handoff before each runtime state change and after every verified unit, not only when asked to pause. Keep one current checkpoint above clearly historical evidence: active task and user decisions, exact artifact and trace paths, process identity, completed and pending checks, authorization limits, and the next executable step. Record whether diagnostic capture remains enabled and how to disable it while preserving evidence and the user's intended app-running state. This lets a fresh session recover a partially completed relaunch without repeating it or losing the incident trace.

Treat intermittent native-feedback fallback as an unresolved trigger until evidence identifies why control eligibility was lost. Separate whether recovery and discarded input match the approved policy from whether rapid input should have caused the failure at all; a plausible recovery sequence is not proof that the trigger was legitimate.

For permission-sensitive opt-in capture on an existing installed artifact, follow `references/tcc-login-item-probes.md` before invoking a convenience measurement command.

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
