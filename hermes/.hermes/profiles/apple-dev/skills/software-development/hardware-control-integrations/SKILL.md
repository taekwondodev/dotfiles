---
name: hardware-control-integrations
description: Use when native apps control physical hardware.
---

# Hardware Control Integrations

Build native hardware-control paths around a resolved device session rather than a compiled identity or an implicit “active” Boolean.

## Procedure

1. **Trace identity end to end.** Inspect the OS-facing discovery API, the transport-facing identity, and the existing operation path. Record which observed fields correlate the same physical device across both boundaries; do not invent a whitelist or user-entered identifier when runtime evidence can resolve it.
2. **Define the session shape first.** Bind the resolved identity, display name, independently confirmed capabilities, current state, and lifecycle generation into one typed session. Pass that session identity explicitly through every queued intent and hardware operation.
3. **Fail closed at discovery.** Resolve exactly one physical destination before opening a transport or writing. Treat no match, ambiguity, and missing endpoint association as unavailable; never select the first “likely” device.
4. **Model partial capability results.** Represent an explicitly unsupported command separately from malformed and transient failures. Preserve valid state from one capability when another is unsupported; otherwise an all-or-nothing read disables working hardware behavior.
5. **Invalidate before switching.** On OS destination or topology changes, advance the generation, discard queued work, resolve and reread the new target, and seed intent from that target’s own state. Re-check identity immediately before each write; a stale operation may finish only against its original identity and must never transfer desired state to the replacement target.
6. **Route input by capability.** Consume both key phases only for supported commands. Pass unsupported command down/up pairs through to the OS without synthetic feedback or emulation.
7. **Test at domain and service seams.** Use a multi-device fake keyed by hardware identity. Prove switching seeds from the new device, stale-generation work writes nothing, writes name their target, partial capability success stays eligible, and transient reads recover. Do not unit-test OS handlers or repositories merely to reach private transport details.
8. **Exercise the real artifact proportionally.** Run the repository suite and strict build, install and verify the signed app, then manually switch each in-scope physical destination and an ordinary OS destination. Confirm destination-specific writes, unsupported-command passthrough, and device-labelled feedback; restore reversible hardware values.

## Pitfalls

- Search every protocol implementer and test fake before changing an identity-bearing port; hand-rolled fakes otherwise preserve the implicit destination and let stale-target bugs escape.
- Keep optional identity fields optional at both discovery and transport matching; requiring absent serial data silently makes a resolvable device unavailable.
- Distinguish a syntactically valid protocol rejection from malformed bytes before mapping errors; collapsing both into one parser failure defeats capability discovery and bounded recovery.
- Report hardware paths as unproven until the actual connected topology is exercised, even when unit tests, compilation, installation, and process verification pass.
