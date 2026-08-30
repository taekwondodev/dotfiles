---
name: macos-integration-debugging
description: "Use when debugging macOS app integrations with local tools."
---

# macOS Integration Debugging

Use this skill when a native macOS app integrates with a local CLI, profile system, database, or background agent and the UI shows missing, stale, or unavailable data.

## Core rule

Do not fix the presentation layer until the producer's real data contract is verified. A fixture or an invented JSON schema can make an adapter look complete while the running producer never writes that artifact.

## Workflow

1. **Capture the exact symptom.** Identify the UI state and the domain result behind it (`missing`, `unreadable`, `malformed`, `offline`, or `empty`).
2. **Resolve runtime configuration.** Check the effective environment variables, profile root, current user, and app sandbox/container assumptions exactly as the app does.
3. **Probe expected artifacts.** Check candidate paths for existence and type without printing credentials, tokens, cookies, prompts, or transcript contents. Record only safe metadata.
4. **Verify the producer.** Search the producer's source and official docs for the writer, schema, and lifecycle. Confirm that the producer actually creates the artifact on the target machine.
5. **Inspect an authoritative source.** Prefer, in order: a documented local export, a stable database schema, a runtime state/API used by the producer, or a CLI implementation. Do not assume an app's private JSON contract is real because the consumer can parse it.
6. **Trace each boundary.** Record what enters and exits Repository, Service, and Handler. Preserve error distinctions across boundaries: infrastructure errors stay inside the adapter; the Service maps them to domain-facing unavailable states; the UI renders those states explicitly.
7. **Build a red-capable probe.** Add a small deterministic test or script that reproduces the exact unavailable state and turns green only when the real source is read. Use secret-free fixtures for malformed/missing cases.
8. **Choose the smallest durable integration.** Reuse the producer's existing authentication and state when possible. Avoid separate provider logins, scraping, or copying secrets into the app. If no supported source exists, add a verified bridge rather than inventing a file contract.
9. **Verify lifecycle behavior.** For always-on menu bar apps, do not attach long-running refresh solely to a popover `.task`; own it in the app/model lifecycle. Use cancellation-aware async loops, one shared actor/service for manual and automatic refresh, and explicit stale/offline timestamps.

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
