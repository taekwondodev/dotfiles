# Unified Logging capture for a live app

Capture a running macOS app's OSLog output without touching the app, its permissions, or its main loop.

Armed capture before launch (background to a file):

    log stream --style compact --predicate 'subsystem == "<bundle-id>"' > trace.log

Recover a window after the fact (the capture must survive an app that hangs or is killed):

    log show --last 5m --style compact --predicate 'subsystem == "<bundle-id>"'

Rules:

- A background `log stream` writing to a file is independent of the app main loop, so it keeps recording while the app hangs or dies. `log show --last` over the run window is the fallback when the stream drops lines.
- Narrow with `subsystem ==` and `category ==` so you do not capture unrelated system events.
- The raw stream is untrusted input: decode and validate each fixed-field line at its boundary before any structured assessment.
- A killed process(SIGTERM/SIGKILL) does not run `applicationWillTerminate`, so a normal-shutdown marker is legitimately absent and the trace self-reports as incomplete. That is a signal, not a diagnostic failure.
- Record the exact PID and the installed executable SHA256 beside the artifact: process metadata binds the producer, and a hash binds the artifact on a dirty tree where HEAD alone is not identity.