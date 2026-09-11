# MenuBarExtra(.window): the lingering scroll bar may be the panel-host NSScrollView, not the SwiftUI ScrollView

Empirically confirmed on macOS 26.5 (Swift 6.3). Distinguishes two scroll containers that
look identical in a popover screenshot.

## Symptom

A `MenuBarExtra(.window)` popover shows a vertical scroll bar on the right `even though`
the code has `.scrollIndicators(.hidden)` on the ScrollView and there is only ONE `ScrollView`
in the source. The bar is persistent (visible without scrolling) and the content is not
clipped / all rows visible.

## Distinguish the two scroll containers

- **SwiftUI `ScrollView` scroller** — `.scrollIndicators(.hidden)` DOES hide this one.
- **The `MenuBarExtra(.window)` panel host `NSScrollView`** — this is the AppKit scroll
  container the panel wraps around the whole SwiftUI content when content exceeds the
  panel's usable height. `.scrollIndicators(.hidden)` does NOT reach it, so the bar stays.

Screenshot signature of the host scroller: full-height track + a visible gutter column
between content and the bar + content not clipped (the panel is scrolling the whole content,
not the inner list).

## Why it shows up

The bar appears when the total content height exceeds `maxHeight`. It is not a SwiftUI
modifier regression. An ADR or issue may claim `.scrollIndicators(.hidden)` fixed it — but if
that ADR's verification line says the final NSPopover check was `manual` (cua-driver cannot
enumerate a menu-bar NSPopover), then the hiding was only ever proven on a normal window
harness, never on the real panel.

## Decisive verification method (commit bisection on the real panel)

Do NOT trust static inspection or a windowed harness. Prove whether the modifier ever worked:

1. `git worktree add -d /tmp/hum-<sha> <sha>` at the commit that INTRODUCED the hiding.
2. `./scripts/build-app.sh` in that worktree to install + launch the real `.app`.
   - If the app is already running, close it first; the script asks on `/dev/tty` which is
     unavailable in a headless/agent shell — do `pkill -f "HermesUsageMonitor.app/Contents/MacOS"`
     before building, or it exits 1.
3. Have the user open the popover (no scrolling) and report whether the bar is visible.
4. If it is STILL visible at the commit that added `.scrollIndicators(.hidden)`, the modifier
   never suppressed the panel-host scroller → the design premise is wrong, not the code.
5. Clean up: `git worktree remove --force <dir>` + `git worktree prune`, then reinstall HEAD.

## Fix: walk the panel view hierarchy and disable the host scroller (VALIDATED implementation)

Option A is implemented and validates at every automated seam: it compiles clean under
`-strict-concurrency=complete`, the whole test suite passes, and `make build` assembles,
signs, installs and launches the real `.app`. Recorded here because the previous draft listed
it as untested; the user's pixel-level visual confirmation was still pending at session end
(do not claim a visual pass until the user confirms).

Key shape of the working implementation:

- An `NSViewRepresentable` (e.g. `PanelScrollChromeRemover`) mounted with `.background(...)`
  on the popover content.
- Its `NSView` subclass walks `window.contentView` recursively and sets
  `scrollView.hasVerticalScroller = false` on every `NSScrollView` it finds (the host panel
  scroller and the inner one). Keep `verticalScrollElasticity` as-is: wheel/trackpad scrolling
  still works on an `NSScrollView` even with the scroller removed.
- **Timing mitigation for the host-window-not-yet-mounted risk** (the onAppear worry): kick
  the walk from `viewDidMoveToWindow()` AND re-run it a few times on `DispatchQueue.main`
  with short delays (e.g. `[0.0, 0.08, 0.25]`) so a late-mounted host scroller is still
  caught.
- The SwiftUI `.scrollIndicators(.hidden)` on the inner `ScrollView` stays; it is not harmful
  and hides the inner scroller, while the representable removes the host one.

## Alternative fix directions

- Keep content never exceeding `maxHeight` so there is nothing for the panel to scroll.
  Robust in spirit but breaks under dynamic expansion (accounting / reset sections).
- Leave `menuBarExtraStyle(.window)` for a manually-managed `NSPopover` with full scroller
  control — heavier, changes interaction, an architecture decision.

Re-validate on the real panel before switching to an alternative or declaring a visual pass.

## Related note

Do NOT run `tccutil reset ScreenCapture` during browser-less investigation: it revokes the
Screen Recording permission and `screencapture` then fails with
`could not create image from display`.
