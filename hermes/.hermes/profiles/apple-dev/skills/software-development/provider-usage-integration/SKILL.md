---
name: provider-usage-integration
description: "Integrate real provider usage/quota sources safely."
---

# Provider Usage Integration

Use this skill when a native app or utility must display AI-provider usage, quotas, balances, rate limits, or local accounting—especially when the provider is accessed through an agent framework or CLI.

## Core rule

**Do not invent a persistence contract from the desired UI.** First establish where the authoritative data actually lives, who owns its authentication, and whether the value is durable, live, estimated, or unavailable.

## Workflow

1. **Map the data sources.** Resolve active profile roots separately from shared/account roots. Inspect the owning agent's source for state databases, CLI commands, in-memory rate-limit state, and provider-specific account endpoints.
2. **Build a red-capable probe.** Run a direct command/API probe that prints only safe metadata: provider identifiers, endpoint names, schema keys, row counts, aggregate token/call totals, and quota windows. Never print keys, cookies, prompts, transcripts, or raw authorization headers.
3. **Separate measures.** Model local accounting (tokens, requests, models, costs), provider quota (used/remaining/reset), and unavailable/error states as different concepts. Never derive a quota percentage from historical tokens unless the provider explicitly defines that relationship.
4. **Prefer the owning system's bridge.** If quota is only available inside an agent process, add a machine-readable command/export in that agent or a deliberate local bridge. Reuse its authentication; do not make the app perform a second provider login.
5. **Define typed contracts.** Use domain types for subscription, window kind, timestamp, freshness, source, reset, and unavailable reasons. Keep provider technical identifiers behind a mapping to commercial subscriptions.
6. **Make adapters safe.** Read databases in read-only mode. Pass subprocess arguments directly, never through shell interpolation. Suppress or drain stderr, enforce a hard timeout, terminate hung children, and map failures at the adapter boundary.
7. **Test the seams.** Unit-test Domain/Service behavior with independent fixtures; put filesystem, SQLite, CLI, and process tests in integration targets. Cover valid data, partial fields, malformed payloads, unsupported versions, provider unavailable states, duplicate profiles, and conflicting snapshots.
8. **Verify the real path.** Run the live probe, the full test suite, strict-concurrency/build checks, and a release build. Report clearly when a provider still exposes consumption but not remaining quota.

## Design guidance

- Keep the UI quota-first when quota exists; show local accounting as secondary detail.
- Always show freshness and acquisition/check timestamps distinctly.
- Preserve the last valid snapshot when a subsequent refresh is offline, marking it stale.
- Do not sum duplicate account-global quota snapshots across profiles.
- Make refresh and notification services actors or otherwise isolated when mutable baseline/deduplication state is involved.
- Keep notification payloads free of usage details and secrets.

## Window identity hardening

When a provider adds or renames quota windows, preserve the raw technical identity through every adapter transformation. Do not reconstruct an intermediate snapshot with only `label`, because a later mapper may let the label spoof the technical kind.

Validate supplied technical identities before normalization. Track whether the field was absent versus present-but-malformed, and reject the latter rather than falling back to a label. Use normalization only for classification; preserve an accepted unknown technical identity verbatim in the wire contract. Bind provider identity to the declared commercial subscription at the command boundary, so a payload cannot opt into ChatGPT-only opaque-window behavior by changing only its subscription string. Typed opaque identity wrappers must validate both construction and decoding, because synthesized Codable decoding can bypass the validating initializer.

For duplicate ChatGPT candidates, keep provider order and assign the first occurrence its base identity, then `#2`, `#3`, and so on. Maintain a used-identity set while assigning suffixes, so an emitted identity that already contains a suffix cannot collide with a later duplicate. Test this through the executable bridge boundary, including technical-kind versus label conflicts, missing-kind label fallback, malformed identities, provider/subscription mismatches, and duplicate suffix collisions. After fixing review findings, rerun both Standards and Spec reviews from the same fixed point before committing.

## References

- `references/provider-bridge.md` — source-tracing notes and a redacted example of a machine-readable provider usage bridge.
- `references/provider-window-evolution.md` — preserve unknown quota windows and evolve typed bridge contracts without breaking lifecycle behavior.
