---
name: macos-menu-bar-development
description: "Use when building SwiftUI macOS menu bar utilities."
---

# macOS Menu Bar Development

Use this skill for native SwiftUI macOS utilities that live in the menu bar, especially apps using `MenuBarExtra` with a popover or window-style panel.

## Architecture

- Keep domain and Service logic independent of SwiftUI and AppKit.
- Put `MenuBarExtra`, popover views, `UserNotifications`, and asset loading in the Handler/app target.
- Inject Repository and Service ports from the composition root; do not let views construct database/process adapters directly.
- Use Swift 6.2 value types and actors for refresh state. Keep subprocess and filesystem failures explicit at the Service boundary.
- For persistent utilities, make automatic refresh lifecycle independent of the popover's visibility when the requirement says the app is always active.

## Cold launch and first frame

- Define the first meaningful frame for an `LSUIElement` app as the first usable menu-bar representation, not a Dock bounce the app never displays.
- Keep app/scene initialization limited to main-actor lifecycle work and construction of lightweight, immediately renderable state. Defer file, database, subprocess, network, and decoding work behind explicit non-main isolation boundaries.
- Audit stored-property default expressions as part of launch: they run before the initializer body and can accidentally construct the same model twice when `_property = State(initialValue:)` replaces an existing default.
- Do not treat `Task {}` as an off-main boundary. A task created from `@MainActor` inherits that isolation; use an actor or an explicitly nonisolated async service returning `Sendable` values, then apply results on `@MainActor`.
- Inspect synchronous calls after every `await` in a main-actor refresh path. They may occur after the literal first frame yet still freeze the launch experience.
- Establish a repeated cold-launch baseline before choosing a regression budget. Record the build, workload, sample count, median, and p95; verify that the measurement observes the persistent agent process rather than a transient launcher process.
- See `references/cold-launch-and-first-frame.md` for the audit and measurement procedure.

## Popover sizing

A `ScrollView` constrained only with `maxHeight` can receive almost no intrinsic height inside `MenuBarExtra(.window)`, producing a blank or extremely short popover. Give the bounded container an explicit width and stable `minHeight`/`idealHeight` plus a `maxHeight`, for example a compact minimum and a larger maximum. Keep the `ScrollView` as the container so content beyond the maximum scrolls vertically.

When a layout bug is reported as "the menu opens but shows nothing":

1. Reproduce with the actual menu bar executable, not only `swift test`.
2. Inspect the `ScrollView`'s proposed/intrinsic height and every surrounding `frame` modifier.
3. Add a minimum/ideal height before changing data or view content.
4. Relaunch the actual executable and visually confirm the popover.
5. Keep a build/test regression check; UI smoke confirmation may be manual because Swift Testing does not cover SwiftUI UI interaction.

## Disclosure controls

For expandable secondary content, use `DisclosureGroup` with a real `@Binding`:

- the parent owns `Set<Identity>` or equivalent expansion state;
- the child receives `@Binding var isExpanded: Bool`;
- the setter must assign the supplied Boolean value, not blindly toggle on every setter call;
- keep the expanded content `frame(maxWidth: .infinity, alignment: .leading)` so it does not widen the popover;
- keep primary quota/status content outside the disclosure.

## Identity icons and status

Separate identity from state:

- the menu bar app mark and provider icons remain stable across live, stale, offline, unavailable, and exhausted states;
- quota/status belongs in labels, meters, and state text, never icon color or icon swaps;
- user-provided image assets need resource-bundle wiring, light/dark contrast checks, and VoiceOver labels on their containing controls;
- decorative images inside a labelled card should be accessibility-hidden to avoid duplicate announcements.

## Refresh and notifications

- Use an actor for refresh state and inject a clock/source in tests.
- Use cancellation-aware `Task.sleep` for long-lived refresh loops.
- Keep manual refresh and automatic refresh on the same Service path.
- Retain the last valid snapshot when the source is offline and mark it stale; show both the last snapshot acquisition time and the current check time.
- Establish a silent baseline for reset detection so app restart does not generate retroactive notifications.
- Group simultaneous reset events into one notification and keep notification content free of tokens, credentials, prompts, and transcript data.

## Verification checklist

- `swift test`
- `swift build -c release -Xswiftc -strict-concurrency=complete`
- `git diff --check`
- Launch the actual menu bar executable and manually inspect the popover height, scrolling, disclosure behavior, icons, and empty/offline states.
- If a browser/desktop capture tool cannot expose the menu bar executable, report that limitation rather than claiming a visual pass; verify process liveness and build output separately.

## References

- `references/cold-launch-and-first-frame.md` — launch-path audit, actor-boundary checks, and baseline requirements for `LSUIElement` utilities.
- `references/popover-sizing-and-smoke.md` — focused reproduction and verification notes for tiny/blank `MenuBarExtra` popovers.
