# ChatGPT/Codex manual reset credits

Manual reset credits are distinct from provider quota-window resets. Do not reuse quota reset-transition semantics for them.

## Provider model

- `available_count` means credits are banked on the account.
- `applicable_available_count` means credits can be redeemed against the current exhausted quota state. Availability and applicability are separate UI states.
- The reset-credit list endpoint may expose one record per credit with status, title, grant timestamp, and expiry timestamp. Use provider timestamps; never estimate expiry.
- A full reset restores both the short session window and the longer weekly window.
- When multiple credits exist, represent the total count and the nearest expiry. Redemption should consume the earliest-expiring applicable credit when the provider supports that ordering; otherwise do not claim a client-selected credit.

## Safe redemption

- Redemption is a provider write and an exception to an otherwise read-only monitor. Gate it behind explicit product approval, provider-declared applicability, and a confirmation dialog.
- Do not expose a force path that can spend a credit before exhaustion unless the product explicitly chooses that risk.
- Use an idempotency key for the consume request. Refresh quota and credit state immediately after success.
- Show success and failure inline. Avoid a duplicate generic quota-reset notification for a reset the user just redeemed intentionally.

## Expiry notifications

- Dedupe expiry alerts by credit identity and expiry bucket, persisting the delivered state across app restarts.
- If several credits share the same expiry, send one aggregated notification for that deadline rather than one alert per credit.
- A credit first observed inside the notification window may notify once; an already expired credit must not.

## UI states

Keep these values distinct and explicit:

- total banked credits;
- whether any credit is applicable now;
- nearest provider-reported expiry;
- unavailable/error state.

A compact provider-card pattern is: a badge when count is positive, followed after quota snapshot metadata by a secondary `Reset manuale` disclosure before local accounting. Keep empty/zero-state behavior as an explicit design decision rather than silently hiding the capability.
