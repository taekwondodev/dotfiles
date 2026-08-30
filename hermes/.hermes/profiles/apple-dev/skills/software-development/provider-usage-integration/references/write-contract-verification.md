# Verify the real write contract before implementing a provider-integration ticket

## When this bites

A spec/ticket for a provider feature can be written from the desired UI or from an
assumed API shape, and that shape may not match the real provider. On HermesUsageMonitor
(ticket #35, "redeem the nearest applicable reset"), the ticket required sending the
selected credit's opaque `credit_id` to the provider `consume` endpoint. Reading the real
Hermes upstream source (`agent/account_usage.py`, `redeem_codex_reset_credit`) showed the
endpoint does NOT accept a credit id: the POST body carries only a fresh UUID idempotency
key (`redeem_request_id`) and the backend picks the next available credit. It also has a
no-force exhaustion guard absent from the ticket.

Implementing to the ticket would have built a consume call that sends a credit id the
backend ignores. The correct move was to stop, surface the gap, and align the spec (to-spec)
before writing code.

## The durable rule

Before implementing any provider write (redeem, purchase, transfer, refresh mutation),
confirm the real wire contract:

1. Read the owning system's authoritative source (the agent/CLI checkout, not just docs). On
   Hermes: `~/.hermes/hermes-agent/agent/account_usage.py` is the source of truth.
2. Check the actual request body fields and the response outcome codes. The ticket may
   describe a `credit_id`, `force`, or ordering guarantee that does not exist on the wire.
3. Reconcile ANY mismatch with the user before implementing: the ticket can be code-shaped
   wrong in a way a unit test cannot catch, because the test would encode the same wrong
   assumption.
4. When the wire has no credit selection, "select the nearest" becomes display-only
   information for the confirmation dialog, never a field sent to the provider.

## Idempotency and verification for irrevocable writes

Writes that may be irreversible need the same audit as the wire contract:

- One confirmed user action owns one idempotency key. A retry of the same unresolved attempt
  reuses that exact key; a new confirmation after a coherent refresh generates a new key.
- A fixed process timeout and structured args (never shell interpolation). The endpooint
  accepts no `credit_id`; the server chooses the credit, so the client must not guess.
- Distinguish DEFINITE outcomes (success / already-redeemed / nothing-to-reset / no-credit /
  auth-or-HTTP rejection) from UNVERIFIED (timeout after send, lost or malformed response).
  Unverified must not look like definite failure: it should block further redemption until a
  coherent live refresh re-establishes provider state.
- No force path in the app. If the provider refuses a no-force redemption when a rate-limit
  window is not exhausted, replicate that guard client-side (enable the action only when a
  quota window is fully used) so the confirmation never fails for a not-exhausted rejection.

## Redemption-triggered refresh

A confirmed write often triggers an immediate live refresh. That refresh must NOT emit the
generic quota-reset notification for the same observation, or the user gets a duplicate:
tag the write-triggered refresh to suppress just that one observation while leaving ordinary
manual/automatic refresh behavior unchanged.