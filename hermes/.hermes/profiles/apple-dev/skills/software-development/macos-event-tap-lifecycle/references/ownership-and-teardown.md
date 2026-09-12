# Ownership and Teardown Reference

## Resource ownership matrix

| Resource or action | Owner | Cross-boundary representation |
| --- | --- | --- |
| `CGEvent.tapCreate` and tap enable/status | dedicated owner thread | typed async result |
| `CFMachPortCreateRunLoopSource` and source attach/remove | dedicated owner thread | owner command |
| `CFMachPortInvalidate` and final tap release | dedicated owner thread | completed stop waiter |
| callback parsing/admission | callback context on owner thread | Sendable Domain handles and values |
| bounded delivery queue and capacity | shared Domain gate | `AdmittedMediaKey` values |
| consumer, OSD, intent reduction, Service submission | MainActor adapter | delegate delivery after stale check |
| permission polling and lifecycle policy | MainActor coordinator | captured generation/token |

The owner may hold a framework reference in thread-confined storage. The shared state may hold only the handles needed to wake or wait for that owner; it must not execute framework calls while locked.

## Owner-run-loop command bridge

1. Start one private thread and install a private `CFRunLoopSource`.
2. Under a narrow lock, append a `@Sendable` command and copy the run-loop/source handles needed to wake it.
3. Unlock, then call `CFRunLoopSourceSignal` and `CFRunLoopWakeUp`.
4. On the owner thread, drain and clear the command list under the lock, unlock, and execute commands one by one.
5. During stop, run source removal, tap invalidation, callback-context clearing, and Domain tap release on the owner thread. Resume all checked-continuation waiters only after teardown.
6. If the run loop exits without the stop command, conditionally tear down any remaining resources before clearing shared readiness state.

Use `@unchecked Sendable` only when the object has an explicit thread-confinement invariant and every cross-thread field is covered by a lock or owner rule. The annotation is not a replacement for a proof.

## Generation-fenced status flow

```text
capture lifecycleGeneration + pollingGeneration
    -> await owner.status() / permission result
    -> if either token or phase changed: return stale with no side effect
    -> otherwise apply enabled/disabled/unavailable policy
```

Do not collapse stale and unavailable into one enum case. A stale result can arrive after reopen, sleep, output change, suspension, or a new poller has already changed the state. Applying the old failure can cancel the new poller or suspend the new session.

## Lifecycle table

| Event | Before owner call | Owner action | After owner call |
| --- | --- | --- | --- |
| suspension/overflow | latch suspension and close admission | teardown tap | Service gets a non-permitted revalidation for the captured generation |
| sleep | increment generation and discard pending work | stop owner | remain sleeping; stale tasks do nothing |
| wake from active sleep | wait for old owner release | stop is idempotent | begin fresh validation; do not publish from wake alone |
| wake from suspended/unavailable sleep | keep lifecycle outside eligibility | ensure old owner is gone | remain suspended/unavailable; do not restart polling implicitly |
| reopen | require no active old owner | create only for new generation | start polling and Service validation only if generation still matches |
| termination | mark stopped and invalidate admission | await asynchronous cleanup | emit `sessionEnded` only on clean cleanup; fallback only replies |

Every asynchronous completion must re-check `stopped` and sleep state as well as its generation. A guard before an `await` is insufficient.

## Termination fallback

Use a local thread-safe reply gate shared by the cleanup task and a bounded watchdog:

- the cleanup path stops the owner, completes the final non-permitted Service revalidation, claims the gate, records `sessionEnded`, and replies;
- the watchdog claims the same gate after the bound and replies without recording `sessionEnded`;
- the watchdog must not require the coordinator to remain alive, because AppKit can release the delegate while termination is pending;
- cancellation of the cleanup task must not cancel the independent fallback path.

The bound is a deadlock escape hatch, not a teardown SLA or performance claim. Keep it explicit in code and keep incomplete traces distinguishable from clean sessions.

## Verification checklist

- Search for `@MainActor`, `await`, semaphore waits, joins, and framework calls in the callback path.
- Verify the event mask/filter and queue capacity against the frozen contract.
- Exercise Domain/Service seam tests for overflow, stale generations, release pairing, sleep/wake, and Service serialization.
- Run the project's test, check, and strict-concurrency Release build commands, then `make build` and the user's manual sequence on the installed app (keys, bursts, revoke grant while running, regrant, reopen, quit).
- List what the seam tests leave unproven and what the manual run covered: callback scheduling/duration, tap creation/disable/teardown effects, Accessibility behavior, OSD draw, wakeups, physical hardware effects.
