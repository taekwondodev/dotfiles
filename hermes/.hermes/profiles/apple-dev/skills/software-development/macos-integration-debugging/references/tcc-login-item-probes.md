# TCC and login-item probe checklist

Use this reference for macOS experiments involving Accessibility, Input Monitoring, event taps, `SMAppService`, or logout/login continuity.

## Static triage after a system-input incident

Use this branch before live permission triage when a prior experiment blocked system input and the app is stopped. Keep it stopped until runtime work is separately authorized.

1. Reconcile exact process state and HEAD with the handoff. Treat capture-manifest labels such as app-running as historical observations, not live status. Compare installed executable hashes with retained capture metadata when artifact continuity matters; a match does not prove the dirty source produced those bytes.
2. Trace the event mask, parser, pass-through/consume branches, and overlay mouse behavior. Separate explicit click suppression from a stalled event-delivery path; absence of a mouse filter does not exonerate the process.
3. Follow permission observation through tap disable, teardown, and recreation, including callback-triggered revalidation. Compare each suspect function with its baseline before calling it a regression. Distinguish callback-triggered retries from periodic polling and hardware-recovery backoff.
4. Inspect the callback's run loop, synchronous delegate/UI work, and every lock body it reaches. Use local SDK headers, located through `xcrun --show-sdk-path`, to check ownership and disabled-notification contracts. Do not equate a disabled-tap notification with proof of permission revocation or declare an undocumented teardown ordering fix necessary.
5. Inventory existing trace stages and search tests for the actual interceptor/coordinator symbols. Routing or Service permission tests do not exercise OS-owned tap teardown. Report missing lifecycle evidence explicitly rather than interpreting absent accepted-input events as a known cause.
6. Finish with established facts, conditional source-level mechanisms, and the evidence needed to distinguish them. A possible repeated disable/recreate sequence is not an observed loop. If evidence is insufficient, retain the unknown cause and request a separate decision on diagnostics; do not present a speculative fix or reproduction recipe as verified.

## Live permission triage

Use the following only within an approved runtime scope, with no unresolved system-input incident blocking it. Before rebuilding, resetting TCC, or restarting an app that passes input through:

1. Verify the exact installed process is alive and trace which permission the implementation actually requires.
2. Ask the user to inspect that app under System Settings > Privacy & Security > the required permission. Record whether the entry is absent, disabled, or enabled; request no additional permission merely as a diagnostic shortcut.
3. If the entry is disabled, have the user grant it while the app remains running, allow its documented observation/revalidation path to run, and repeat the same input. This tests live grant recovery without introducing a new process identity.
4. Record permission resolution separately from proof of recovery without relaunch. Confirm the absence of a user restart or compare exact process identity before and after before claiming the latter.
5. If the visible toggle is already enabled but interception remains unavailable, separate effective trust, event-tap creation, target eligibility, and trusted initial state before choosing a reset or code change.

## Identity-safe launch

A TCC answer is meaningful only for the process identity under test. Use the fresh-launch sequence below for launch/reset experiments, not for grant or revocation while running, where restarting would destroy the behavior being tested.

1. Stop every process whose command begins with the exact app executable path. Background terminal runners may expose a shell PID while leaving the child executable alive, so enumerate and terminate the executable itself.
2. Apply the intended permission transition.
3. Launch a fresh app instance through LaunchServices, for example `open -na "/path/App.app" --args <probe arguments>`.
4. Capture the permission API result and the capability result separately. For an event tap, record both preflight/trust state and whether tap creation actually succeeded.
5. When attribution is uncertain, inspect unified TCC logs for the accessing and responsible identities. A terminal or automation agent shown as the responsible process invalidates an app-identity proof.

A direct executable launch from an agent-controlled terminal is suitable for ordinary diagnostics, but not for proving the app's independent TCC identity.

## Opt-in capture without changing the installed identity

Use this sequence when diagnostic flags already exist in the installed app and replacing its build could disturb permission attribution.

1. Read the measurement command and recorder implementation first. If the command rebuilds, installs, or resigns, reuse the repository's exact-process stop, LaunchServices launch, and verification helpers directly instead; preserve the existing bundle when capture needs only launch arguments.
2. Create a unique durable evidence directory. Before stopping anything, persist a manifest with the intended trace path, existing process identity, installed executable hash, capture scope, and recovery instructions. Update it after stop, after launch, and on failure so interruption leaves an actionable checkpoint.
3. Relaunch only the exact installed app through LaunchServices with the inspected diagnostic flags. Do not synthesize input or add hardware proof merely to establish that recording is armed.
4. Read back the real trace and independently verify the sole live process, valid signature, unchanged executable hash, trace schema, trace process identity, and actual session-start event. A startup-only trace proves recorder activation, not successful interception or a reproduced fault. Label a source revision from a dirty tree as a baseline; use the executable hash for artifact identity.
5. Inventory what the recorder can distinguish before requesting reproduction. Accepted-input and hardware-outcome events may reveal a transport failure but cannot identify permission, event-tap, or lifecycle causes unless those transitions are recorded. Preserve unknown causes rather than inferring them from missing input events.
6. Inspect retention and persistence costs before leaving capture enabled. A recorder that accumulates events or rewrites full snapshots needs a short user-guided capture window and explicit stop point, not indefinite unattended use. Recording itself can affect timing; do not claim equivalence with its inactive path without evidence.
7. After the user reports recurrence or completes the agreed window, preserve and inspect the exact trace. Disable launch-argument capture by stopping the exact owner and reopening normally without the flags, then verify the live artifact again. Keep evidence and document the resulting running/capture state before a handoff.

## Permission matrix

Exercise each relevant state independently:

- neither permission granted;
- Accessibility only;
- Input Monitoring only;
- both granted;
- grant while running;
- revocation while running.

For each state, record permission APIs, capability creation, event consumption, relaunch requirement, and revocation detection. A successful `tccutil reset` message is not evidence of the resulting state. Verify launch/reset cases from a fresh LaunchServices-owned process; preserve the existing process for live grant, revocation, and regrant cases.

Ad-hoc builds can change code identity between rebuilds. If a visible TCC toggle and the process result disagree, compare the exact installed build identity and test removing and re-adding that build rather than assuming the toggle applies.

## `SMAppService` lifecycle

Record explicit status transitions around each action:

1. status before registration;
2. registration result and status after registration;
3. whether System Settings requires additional approval;
4. actual next-login launch, observed before any manual app launch by exact executable path and process count;
5. unregister result and status after unregister;
6. background-task disposition, distinguishing enabled, disabled, and absent.

Registration success alone does not prove next-login launch. `sfltool dumpbtm` can show a disabled historical record after unregister, while the app API reports `notRegistered` or `notFound`; record both rather than treating record presence as enabled state.

## Cross-login continuity

Before logout or restart:

- store evidence and backups outside ephemeral directories;
- preserve any needed diagnostic diff on a throwaway branch or durable worktree path;
- write the exact post-login observation command and completion criterion;
- stop the app so the next observation cannot be mistaken for a pre-existing process.

Do not rely on a worktree under `/tmp` surviving logout. If it is deliberately disposable, ensure the installed diagnostic artifact and all evidence needed to finish and restore are already durable.

## Restoration proof

Restore the initial state as its own verified unit:

- unregister the login item and confirm disabled or absent state;
- stop all exact app processes;
- reset only the app's relevant permissions;
- use a fresh LaunchServices-owned diagnostic process to verify the denied state;
- restore the saved bundle and compare its executable hash and bundle contents;
- verify the restored bundle's code signature and zero running processes;
- remove stale worktree metadata only after its diagnostic diff is no longer needed.

Keep raw evidence local unless the task requires publication. Publish only redacted observations and contract decisions.