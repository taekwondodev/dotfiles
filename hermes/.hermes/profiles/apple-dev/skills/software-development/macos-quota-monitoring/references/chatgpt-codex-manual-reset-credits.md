# ChatGPT/Codex manual reset credits

## Distinct domain concept

A banked manual reset credit is not a quota-window boundary reset. Keep these concepts separate in models, UI copy, notifications, and tests:

- **Quota-window reset**: provider-owned passage to a new time window, observed from consecutive quota snapshots.
- **Manual reset credit**: a scarce provider grant that can be redeemed to restore quota before the normal boundary.

A credit can be **available** but **not currently applicable**. Never collapse “owned” and “usable now” into one boolean.

## Provider observations

The ChatGPT/Codex usage response may include:

- `rate_limit_reset_credits.available_count`: banked credits owned by the account.
- `rate_limit_reset_credits.applicable_available_count`: credits the provider currently permits redeeming.

The reset-credit listing endpoint may additionally expose a credit title, description, status, `expires_at`, plan support, and aggregate counts. Treat the provider timestamp as authoritative; do not infer expiry locally.

Do not log or display credit IDs, account IDs, OAuth data, or unrelated raw payload fields. Convert only the allow-listed display fields into the app bridge/domain schema.

## Safe redemption boundary

For a native quota monitor that allows redemption:

1. Keep the feature provider-specific unless another provider exposes equivalent verified semantics.
2. Enable redemption only when the provider reports an applicable credit; do not infer applicability from local percentages.
3. Do not expose a force path in a compact monitoring app unless the product explicitly accepts wasting a credit.
4. Require explicit confirmation describing what resets and how many credits remain.
5. Use the provider/Hermes idempotent redemption path rather than constructing an ad-hoc POST.
6. Refresh quota and credit state immediately after success.
7. Show success inline and suppress a duplicate generic quota-reset notification for the user-initiated redemption.
8. Keep unavailable, expired, already redeemed, nothing-to-reset, and network/auth failures explicit and retryable.

## UI and expiry

Show owned count, applicability, and expiry as separate values. If expiry notifications are desired, schedule from the provider `expires_at`, dedupe them durably, and never invent a replacement expiry after a failed refresh.

## Verification matrix

Cover at minimum:

- available + applicable;
- available + not applicable;
- no credits;
- unsupported plan;
- expired credit;
- confirmation cancellation;
- successful idempotent redemption and immediate refresh;
- backend `nothing_to_reset` without consumption;
- auth/network failure;
- no duplicate quota-reset notification after user-initiated redemption;
- expiry-warning deduplication across app restart.
