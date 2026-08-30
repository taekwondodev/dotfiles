# Per-model accounting display

Use this reference when a popover displays `LocalAccounting` entries containing model names plus aggregate tokens, requests, and cost.

## Safe mapping

- Treat each `LocalAccounting` entry as the atomic observation unit unless the domain provides separate metrics per model.
- Keep the entry's Input, Output, Richieste, and Costo together in one display block.
- If `models` contains multiple names but the metrics are aggregate, join the names in the block title; do not duplicate the aggregate values under each name.
- If a metric is `nil`, render an explicit unavailable value such as `Non disponibile`; never substitute zero.
- If the model list is empty, use an explicit unavailable model label.

## Review checklist

- Does the UI preserve the source observation granularity?
- Can a reader tell which metrics belong together?
- Are missing values visible and honest?
- Is the provider identity already established by the containing card, making repeated technical provider labels redundant?
- Is the pure display transformation tested with both complete and partial entries, including a multi-model aggregate entry?
