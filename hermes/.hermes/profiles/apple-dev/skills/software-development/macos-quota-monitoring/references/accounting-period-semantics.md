# Accounting period semantics

For Hermes local accounting, define a period before presenting totals. Do not call the data “since Hermes was downloaded” unless the source proves that boundary. A useful comparable default is a rolling 30×24-hour window ending at the accounting refresh, applied to every supported subscription.

Apply the cutoff at the Repository boundary using source timestamps such as `last_seen`, before provider/model aggregation. Use an injected Service clock for deterministic boundaries. Include an aggregated row in full when its `last_seen` is inside the window; never prorate tokens, requests, or cost across the boundary because the source lacks event-level allocation.

Timestamp-less legacy sources may remain included for compatibility, but the app must not invent timestamps or claim their exact period is known. Keep the UI unchanged when the semantic correction does not require new dates, badges, or selectors; document the accounting window in the project glossary.

When a spec changes the actual data boundary of a UI parent ticket, confirm the broader Repository + Service + Handler split before publishing. Link the resulting spec as a GitHub sub-issue with `gh issue create --parent <number>` and verify the parent lists it.