---
name: agent-usage-observability
description: Design dashboards over local AI-agent usage records.
version: 0.1.0
author: User, Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [agent-usage, telemetry, dashboards, providers, observability]
    related_skills: []
---

# Agent Usage Observability Skill

Design and implement personal dashboards that report what an AI-agent framework actually observed. Keep local accounting, provider identity, and remote subscription entitlements as separate concepts. This skill covers the read-model boundary and product decisions; it does not invent unsupported provider quotas or encourage credential scraping.

## When to Use

Use when a user wants to monitor several AI subscriptions or model providers through one agent framework, especially in a menu-bar, tray, desktop, or local dashboard app.

Don't use for provider billing systems that have no local agent accounting source and require authoritative remote invoices; use the provider's supported billing API instead.

## Core Model

- **Observed usage:** calls, models, token classes, costs, and timestamps recorded by the agent framework.
- **Remote entitlement:** quota, balance, reset window, plan, and rate-limit state supplied by a verified provider or framework snapshot.
- **Provider card:** the user-facing aggregate for one commercial provider.
- **Technical identity:** the framework provider slug, endpoint, model, task, and accounting source retained for detail and diagnostics.
- **Freshness:** when the underlying record was last observed, distinct from the time the UI refreshed.

## Procedure

1. **Define the contract.** List every metric the user wants and classify it as observed usage, remote entitlement, or derived presentation. Completion means every displayed metric has one classification.
2. **Inventory the framework source.** Inspect its documented export/read model first. If a local database is the only source, isolate it behind one adapter and record the schema/version assumptions. Completion means the adapter has one explicit source boundary.
3. **Normalize records.** Map framework rows into a provider-neutral read model containing provider, model, task, call count, input/output/cache/reasoning tokens, estimated/actual cost, timestamps, entitlement snapshot, and freshness. Completion means the UI needs no provider-specific parsing.
4. **Aggregate conservatively.** Group the primary view by user-facing provider. Keep technical provider and model identifiers in detail. Sum local usage only within a defined time window; never treat tokens as a quota percentage without a declared limit and reset policy. Completion means each aggregate states its window and source.
5. **Handle missing data explicitly.** Show unavailable, stale, unauthenticated, or framework-offline states separately. A missing remote endpoint must not become a guessed quota. Completion means every adapter failure has a user-readable state and diagnostic reason.
6. **Design refresh behavior.** Use scheduled refresh plus manual refresh, and filesystem/database observation only when it is safe and supported. Display the last successful snapshot and its freshness. Completion means the app remains useful when the framework is idle or offline.
7. **Protect credentials and content.** Read only the accounting fields required. Never copy provider tokens into the dashboard store. Keep secrets in the platform credential store and avoid exposing prompts, transcripts, or message bodies in usage views. Completion means a data-flow review identifies every trust boundary.
8. **Verify with fixtures.** Test empty data, one provider, multiple providers, stale data, malformed rows, duplicate rows, cost-unavailable rows, and schema changes. Completion means each state has a deterministic fixture and assertion.

## Architecture Guidance

Use a provider-neutral collector/read-model boundary and a display-only UI. The composition root wires adapters for the framework's accounting source and any verified entitlement source. Keep provider-specific logic in adapters; keep aggregation and presentation based on normalized values.

For a personal native macOS utility, a menu-bar popover is a natural display surface. Keep the icon stable and use a small status badge for freshness, activity, or warning. Hide provider switching controls when there is only one populated provider, following the Omarchy pattern.

## Pitfalls

- Treating ChatGPT, Claude, OpenCode, or Nous subscription pages as APIs without a documented contract.
- Confusing an API-platform usage endpoint with consumer subscription quota.
- Inferring a remote percentage from local token counts.
- Coupling the entire UI to private database table names.
- Summing account-global data from multiple machines or duplicate snapshots.
- Showing a stale value without a timestamp.
- Persisting raw prompts, transcripts, bearer tokens, or cookies in the dashboard.
- Calling a provider “unused” when its records are merely delayed or unavailable.

## Verification

Before calling the design complete, confirm that every card identifies its source, aggregation window, and freshness; remote values are either verified or labeled unavailable; local usage can be reproduced from fixtures; provider-specific code is isolated; and the offline/stale/error states are visible without opening logs.

## References

- `references/hermes-accounting.md` — Hermes accounting fields and the local-versus-remote interpretation.
