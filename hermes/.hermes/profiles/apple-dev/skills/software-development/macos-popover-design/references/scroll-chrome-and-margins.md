# macOS scroll chrome: contentMargins trap, hide-or-pad, and harness measurement

Session-tested findings for native-macOS `ScrollView` layout inside a menu-bar popover or
window, when the overlay scroll bar lands on top of content that fills the full width.

## The `contentMargins(_:for: .scrollContent)` trap

On macOS, `contentMargins(_, for: .scrollContent)` moves the **overlay scroll indicator
together with the content**. It insets the trailing content *and* shifts the scroll bar left
by the same amount, so indicator and content travel as one and a gap is never created. This
was verified by decoding the installed popover's pixels: the scroll bar had moved left by
exactly the inset value (16pt) while the card edge had not cleared it.

Do not use this modifier to "reserve a gutter" or push an overlay scroll bar off the content.
It cannot work on macOS.

## Two ways that DO clear content of an overlay scroll bar

1. **Trailing padding on the scroll content**, not on the scroll view:
   `ScrollView { content.padding(.trailing, N) }`. The overlay indicator stays pinned at the
   scroll view's trailing edge while the cards move left. Measured in a windowed harness:
   ~20pt gap vs ~4pt for the `contentMargins` variant.
   Do NOT add the same inset on the outer `.padding(N)` too: `padding(16)` on the `ScrollView`
   plus `.padding(.trailing, 16)` on the content stacks to ~32pt trailing vs ~16pt leading,
   an asymmetric column. For a symmetric Apple-like look, prefer ONE uniform `.padding(16)`
   and no extra content padding.
2. **Hide the bar**: `.scrollIndicators(.hidden)` and rely on the clipped last row at the
   bottom edge to signal scrollability. macOS HIG: "Because scroll bars aren't always
   visible... displaying partial content at the edge" signals more content. This is the
   cleanest result when the overflow is expected and permanent.

## On-demand scroll bars cannot be forced

On mouse-driven Macs the system can show overlay scroll bars persistently even when
`AppleShowScrollBars` is unset (the effective default still leaves them visible rather than
auto-hiding). SwiftUI's `.automatic` (the default) defers to the OS, so "appear on scroll,
hide when idle" cannot be forced app-side. The app-side choices are `.hidden` or accepting
the OS behavior. If the user wants auto-hide, the lever is their system Appearance setting,
not code.

## Measuring scroll-chrome geometry when the popover can't be captured

cua-driver often cannot enumerate or capture a menu-bar `NSPopover`: it does not appear in
`list_windows`, and `capture(app=...)` finds no window by app name or pid+window_id. That is
a driver limitation, not an app bug, and it blocks on-pixel verification of the real popover.

Workaround that verifies the real engine: build a standalone SwiftUI harness that reproduces
the exact modifier chain (same `ScrollView`, same outer padding, same frame) as a regular
window, launch it, `capture` the window, then measure where the scroll bar and the card edge
sit. When PIL/numpy are unavailable, decode the captured PNG by hand: parse IHDR/IDAT via
`zlib`, unfilter scanlines (filters 0-4), then scan row/column brightness. The overlay scroll
bar is a thin bright vertical bar (col brightness well above the card surface); the card edge
is the last column whose brightness is above background. This gives the direction and
magnitude of a layout change reliably enough to pick between alternatives, even though the
final popover confirmation stays manual.

Keep the harness disposable under `/tmp`; never leave it in the implementation tree.