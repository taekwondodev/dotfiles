---
name: macos-local-companion-integration
description: "Use for macOS apps monitoring local agents."
---

# macOS Local Companion Integration

Use this for native macOS utilities that observe another local agent, CLI, database, gateway, or provider bridge.

## Workflow

1. **Inventory the real producer before designing adapters.** Resolve the source app's effective home/profile from its runtime environment. Enumerate persistent databases, generated files, CLI commands, in-memory state, and remote endpoints.
2. **Build a red-capable probe.** Run the source app's own status/usage command in machine-readable mode when available. Compare its output with the companion app's expected paths and domain model.
3. **Separate data products.** Token/cost accounting, provider identity, quota windows, and rate-limit state often have different sources and lifetimes. Do not infer a quota percentage from historical tokens.
4. **Choose the bridge.** Prefer a source-app CLI/export command that reuses existing authentication. Use read-only SQLite for durable local accounting. Treat in-memory rate-limit data as unavailable until the source app exports it.
5. **Define explicit degradation.** Missing, malformed, unsupported, unauthorized, and unavailable data must remain distinguishable at the domain/UI boundary. Never silently turn an error into an empty successful result.
6. **Implement behind ports.** Keep Repository adapters behind `Sendable` source protocols; keep UI dependent on domain-facing results, not repository errors. Map technical provider identifiers to commercial subscriptions at the adapter boundary.
7. **Bound subprocesses.** Pass arguments as arrays, never shell strings containing secrets. Drain or discard stderr, enforce a timeout, terminate hung children, and avoid unbounded `waitUntilExit()` on a UI refresh path.
8. **Verify in layers.** Use secret-free fixture tests for command JSON and database schemas, integration tests for filesystem/process adapters, a live probe that prints no credentials, strict-concurrency build, release build, and full test suite.

## SwiftUI companion patterns

- Keep refresh state in an actor or `@MainActor` view model with cancellation-aware automatic refresh.
- Preserve the last valid snapshot and mark it stale when a later source read is unavailable.
- Keep identity icons independent from quota/status encoding.
- For dense menu-bar popovers, use an explicit maximum height, vertical `ScrollView`, and collapsed secondary sections with `DisclosureGroup` and a real `Binding<Bool>` setter.

## References

- `references/local-companion-data-bridge.md` — concrete source inventory, bridge safety, profile/root state, and test seams.
