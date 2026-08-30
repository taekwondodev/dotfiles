# Hermes Accounting Reference

## What to consume

Hermes maintains a per-session, per-model usage read model. The important dimensions are:

- `session_id`
- `model`
- `billing_provider`
- `billing_base_url`
- `billing_mode`
- `task`
- `api_call_count`
- `input_tokens`
- `output_tokens`
- `cache_read_tokens`
- `cache_write_tokens`
- `reasoning_tokens`
- `estimated_cost_usd`
- `actual_cost_usd`
- `cost_status`
- `cost_source`
- `first_seen`
- `last_seen`

The exact storage location and schema version are deployment details. Resolve the active Hermes home/profile from its supported configuration or environment rather than hardcoding a user's home path.

## Interpretation

`billing_provider` is the technical accounting identity, not always the commercial subscription name. Build a mapping layer so the primary UI can show names such as Nous Portal, OpenCode Go, or ChatGPT while retaining the raw provider and endpoint for diagnostics.

The local accounting rows are authoritative for what Hermes observed: calls, token categories, model selection, and cost fields. They are not automatically authoritative for a provider's subscription quota. A remote quota or reset should be displayed only when Hermes exposes a verified snapshot or the provider publishes a supported endpoint.

Hermes may also expose provider-specific account, credit, or rate-limit snapshots through its usage/reporting paths. Treat these as optional entitlement data with their own timestamp and source. Keep them separate from session aggregates.

## Adapter contract

A companion app should read through one adapter that returns normalized records and diagnostics. The adapter should:

1. detect the active Hermes profile/home;
2. check schema/version compatibility;
3. read only required accounting columns;
4. aggregate by user-facing provider and explicit time window;
5. preserve technical provider/model identifiers;
6. return freshness and source metadata;
7. classify unavailable, stale, offline, malformed, and unauthenticated states.

Prefer a documented export or stable read model if Hermes provides one. If direct database reading is necessary for a private single-user utility, keep the private dependency behind the adapter and add fixture tests for schema changes.

## Omarchy pattern

Omarchy's Agents panel separates collectors from display: collectors write normalized usage records, and the panel watches/reads those records. Reuse this boundary concept even when Hermes itself is the collector. The menu-bar UI should remain display-only and should not contain provider-specific authentication or scraping logic.

## Privacy boundary

Usage views should expose aggregates, not prompt text or transcript content. Do not copy bearer tokens, refresh tokens, browser cookies, or raw provider credentials into the companion app's database. If a provider credential is ever required for an entitlement adapter, use the platform credential store and make the adapter opt-in.
