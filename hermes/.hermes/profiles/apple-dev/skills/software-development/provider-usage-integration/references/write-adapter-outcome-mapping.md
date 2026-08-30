# Map write-adapter outcomes without a broad exception handler

## The trap

On HermesUsageMonitor ticket #35 ("redeem an applicable manual Full reset safely"), the
provider-write adapter (a Python bridge plugin) wrapped `raise_for_status()` and the whole POST
in a single `except Exception` and mapped every failure to `unverified`. An auth/HTTP error
(401/403/5xx) then entered verification-required state, which blocked ALL future redemptions
instead of presenting the safe rejection dialog the spec required. Only the code-review SPEC axis
caught it; the unit tests stubbed successful and body-code responses, so none exercised the
raised-http-error path.

## The fix

Catch the HTTP status error class explicitly and map it to a definite `rejected`; let only
genuinely ambiguous failures (timeout after send, connection loss, malformed body) fall to
`unverified`. In Python, resolve the error class off the same `httpx` module the adapter already
holds, because a test transport may define its own `HTTPStatusError`:

```python
try:
    response = client.post(consume_url, headers=headers, json={"redeem_request_id": request_id})
    response.raise_for_status()
    payload = response.json() or {}
except Exception as error:
    http_error = getattr(api.httpx, "HTTPStatusError", None)
    if http_error is not None and isinstance(error, http_error):
        return {"status": "rejected"}
    return {"status": "unverified"}
```

On the Swift reader side, add a `rejected` case to the decode mapping so the bridge's `rejected`
status becomes a definite rejection.

## The test you must add

Integration test where the fake transport's `post`/`raise_for_status` raises the HTTP status
error class (define it on the fake `httpx` module so the adapter's `getattr` finds it), then
assert the mapped outcome is `rejected`, not `unverified`. A test that only stubs successful or
body-code responses will not cover this branch.