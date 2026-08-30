# Cold launch and first frame for menu-bar apps

## Quality target

For an `LSUIElement` utility, replace the informal “Dock bounce” proxy with the time from launch request to the first meaningful menu-bar representation. The UI must be able to render an honest waiting, cached, or unavailable state without waiting for provider data.

Apple defines launch time around drawing the first frame and recommends deferring work unrelated to generating it:

- [Reducing your app’s launch time](https://developer.apple.com/documentation/xcode/reducing-your-app-s-launch-time)
- [Optimizing App Launch, WWDC19](https://developer.apple.com/videos/play/wwdc2019/423/)
- [XCTApplicationLaunchMetric](https://developer.apple.com/documentation/xctest/xctapplicationlaunchmetric)
- [OSSignposter](https://developer.apple.com/documentation/os/ossignposter)

## Static launch-path audit

Trace from the `@main App` through stored-property initialization, `init`, scene construction, and the menu-bar label.

1. List every stored-property default expression. Swift evaluates these before the initializer body; replacing a wrapper with `_model = State(initialValue:)` does not make an existing default construction free.
2. Keep only main-required lifecycle work before the frame: AppKit/SwiftUI object creation, single-instance policy when required, and lightweight in-memory state.
3. Flag file access, `UserDefaults` normalization writes, database queries, `Process`, network calls, notification prompts, and non-trivial decoding.
4. Trace each `Task` to its actual isolation boundary. `Task {}` inherits the creator’s actor; the task wrapper alone proves nothing.
5. Prefer service actors or explicitly nonisolated async operations that return `Sendable` values. Keep state application on `@MainActor`.
6. Continue the audit after each `await`. A synchronous database or subprocess call after resuming on `@MainActor` can freeze the opening experience even if the first frame already committed.
7. Keep popover visibility independent from persistent background refresh when that is a product requirement.

## Architecture shape

The smallest useful shape is:

- `@MainActor` composition and observable UI state;
- lightweight initial domain values that render immediately;
- service-owned async refresh entry points;
- an actor boundary around blocking repositories when an async Foundation API is unavailable;
- `Sendable` result values crossing back to the view model;
- no `Task.detached()` escape hatch unless profiling proves it is necessary and ownership remains explicit.

A concurrency regression should use a controlled slow source and prove that a main-actor heartbeat or UI-state action can proceed while the service read is pending. A passing domain test alone does not establish isolation.

## Measurement protocol

1. Measure a release app bundle using one fixed machine state and workload.
2. Ensure the app is not already running and exercise genuine cold launches rather than repeated activations.
3. Use Instruments App Launch, `XCTApplicationLaunchMetric`, or validated lifecycle signposts. For agent apps, verify the recorded PID is the persistent app process; discard traces of a transient launcher or duplicate-instance process.
4. Run enough samples to expose noise and report sample count, median, and p95. Keep raw samples with the result.
5. Establish the first verified baseline before selecting a regression budget. Do not invent a universal millisecond threshold from the phrase “half bounce.”
6. Apply one architectural change at a time and re-run the identical harness. Keep a change only when improvement clears measurement noise and correctness gates remain green.
7. Compilation, process liveness, warm activation, and an `onAppear` callback are useful evidence but are not automatically equivalent to compositor-confirmed first-frame latency; name the exact metric honestly.

## Completion evidence

A launch-performance claim requires:

- traced main-actor and non-main ownership;
- no blocking external work on the main actor in the launch experience;
- a reproducible measurement command or test;
- raw before/after samples with median and p95;
- confirmation that the intended process and milestone were measured;
- normal tests, strict-concurrency build, and actual app-bundle smoke verification.
