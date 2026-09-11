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

## Popover scroll chrome

A persistent right-hand scroll bar in a `MenuBarExtra(.window)` popover with
`.scrollIndicators(.hidden)` present is usually NOT your SwiftUI `ScrollView` scroller — it is
the panel host `NSScrollView` that wraps the whole content when it exceeds `maxHeight`.
`.scrollIndicators(.hidden)` cannot suppress that host scroller. Before changing data or
adding an ADR guaranteeing a hidden bar, prove the premise with a real-panel check, and fix
by disabling the host scroller via an `NSViewRepresentable` hierarchy walk (see
`references/menu-bar-panel-host-scrollbar.md` for the symptom signature, commit-bisection
verification, and the validated fix). A "manual final popover check" note in an ADR
means the hiding was only proven in a windowed harness.

## Popover content cleanup

When removing redundant trailing status content from a popover, remove the separator that only introduced that content and delete presentation helpers that no longer have consumers. Keep the underlying availability, timestamp, refresh, and snapshot state when it remains part of the data contract. Re-scan callers after each deletion so the UI does not retain empty labels, sentinel strings, or dead presentation code.

Verify the resulting edge in every relevant state: live, offline, waiting, persisted, stale, and unavailable. A visual cleanup should reduce the terminal content without changing quota values, reset messaging, accounting disclosures, or popover sizing constraints.

## Hiding the scroll bar on mouse-driven Macs

`.scrollIndicators(.hidden)` does NOT reliably remove a macOS scroll bar: it is
pointer-device aware, and when a mouse is connected the indicators return (typically as a
legacy scroller) the moment the user scrolls, reserving a gutter and reflowing card width.
Use `.scrollIndicators(.never)` to hide indicators regardless of the connected pointing
device. Instrumenting the real menu-bar `ScrollView` (`_NSHostingScrollView`, one instance,
`scrollerStyle == .legacy`) confirmed `hasVerticalScroller` flips back to `true` on scroll
with `.hidden`; walking the view tree to force it off is a fragile workaround that loses the
race to the next re-enable.

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

## Documenting the icons

Template-rendered menu bar marks (renderingIntent `.template`) are monochrome and effectively invisible on a white README page. To showcase them next to the full-color app icon, wrap the template mark in an HTML table cell with a dark background and a light caption:

```html
<table>
  <tr>
    <td align="center"><img src=".../AppIcon.png" width="220" alt="app icon"><br><strong>App icon</strong></td>
    <td align="center" bgcolor="#151515"><img src=".../MenuBarIcon.png" width="180" alt="menu bar mark"><br><strong><font color="#ffffff">Menu bar mark</font></strong></td>
  </tr>
</table>
```

This renders in GitHub-flavored markdown and keeps the template asset legible beside the full-color icon.

## Refresh and notifications

- Use an actor for refresh state and inject a clock/source in tests.
- Use cancellation-aware `Task.sleep` for long-lived refresh loops.
- Keep manual refresh and automatic refresh on the same Service path.
- Retain the last valid snapshot when the source is offline and mark it stale; show both the last snapshot acquisition time and the current check time.
- Establish a silent baseline for reset detection so app restart does not generate retroactive notifications.
- Group simultaneous reset events into one notification and keep notification content free of tokens, credentials, prompts, and transcript data.

## External-display hardware controls

When a user wants a purpose-built monitor-control utility, do not redirect them to installing or trying a third-party GUI app after they reject that path. Treat existing open-source implementations as technical references or disposable command-line probes only, not as the deliverable.

Before designing DDC/CI behavior:

- inspect the live display and audio transport;
- prove read support for the exact VCP feature;
- perform a same-value write followed by read-back so capability is verified without changing the user's setting;
- identify the monitor by stable EDID/system identity, never by a transient display-list index;
- separate DDC transport, active-audio-device detection, media-key interception, and SwiftUI presentation behind explicit ports;
- preserve the last confirmed hardware value when a write fails and expose the failure instead of pretending the optimistic UI value succeeded;
- disclose that Apple Silicon DDC transport and the native system OSD rely on non-public interfaces and are unsuitable for Mac App Store distribution;
- establish the TCC permissions needed by the chosen event tap before promising global media-key interception.

See `references/external-display-ddc-volume.md` for the verified probe sequence, relevant VCP features, event-tap constraints, and implementation boundaries.

## Verification checklist

- `swift test`
- `swift build -c release -Xswiftc -strict-concurrency=complete`
- `git diff --check`
- Launch the actual macOS menu bar executable and manually inspect the popover height, scrolling, disclosure behavior, icons, and empty/offline states.
- For native macOS `MenuBarExtra` UI, use the real app on the Mac. Xcode Preview supports layout work but does not prove menu bar lifecycle or runtime presentation. Do not substitute a device simulator or automated GUI control for the user's visual inspection.
- If the app cannot be exposed for manual inspection, report that limitation rather than claiming a visual pass; verify process liveness and build output separately.

## References

- `references/cold-launch-and-first-frame.md` — launch-path audit, actor-boundary checks, and baseline requirements for `LSUIElement` utilities.
- `references/popover-sizing-and-smoke.md` — focused reproduction and verification notes for tiny/blank `MenuBarExtra` popovers.
- `references/menu-bar-panel-host-scrollbar.md` — lingering scroll bar = panel-host NSScrollView, not the SwiftUI ScrollView; symptom signature, commit-bisection verification, and the validated `NSViewRepresentable` fix that walks the window hierarchy and disables the host scroller.
- `references/external-display-ddc-volume.md` — capability probing, serialized volume/unmute confirmation, Tahoe OSD semantic checks, and zero-safe HUD geometry for hardware volume over DDC/CI.
