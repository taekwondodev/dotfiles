# Overlay scrollbar gutter: contentMargins gotcha and the fix

Fixing the "overlay scrollbar sits on the card content" issue in a macOS menu-bar popover
ScrollView. Verified against a real macOS SwiftUI render and the installed popover's pixels.

## Symptom

A `ScrollView` whose cards fill the full width; the status bar's *overlay* scrollbar floats
over the trailing-edge card content (the reset-countdown / metric column). The accepted
design wants a fixed ~16pt gutter so the scrollbar clearly clears the cards.

## The gotcha (do NOT do this)

```swift
ScrollView(.vertical) { content }
    .contentMargins(.trailing, 16, for: .scrollContent)
```

On macOS, `contentMargins(_:for: .scrollContent)` moves the **overlay scrollbar together
with the content**. The scroll indicator follows the content's trailing extent instead of
staying pinned at the scroll view's frame edge, so content and scrollbar shift inward as
one and never separate. Pixel measurement of the installed popover confirmed the scrollbar
moved left by *exactly* the gutter amount (16pt) while the card edge did not clear it.

This is not popover-specific: an overlay scrollbar follows the content's trailing extent
under `contentMargins` in any hosting context.

## The fix

Reserve the slot with trailing padding on the scroll *content*; that keeps the overlay
scrollbar pinned at the scroll view's trailing edge while the cards move left:

```swift
ScrollView(.vertical) {
    VStack(alignment: .leading, spacing: 0) { /* header, cards, footer */ }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, PopoverLayout.scrollGutter)   // the gutter
}
.padding(16)
.frame(width: 380)
```

Keep the gutter width as a named layout constant (an acceptance value, used by a layout
test). In HermesUsageMonitor this is `PopoverLayout.scrollGutter` (= 16), documented in
`docs/adr/0006-scroll-gutter-via-content-padding.md` and the CONTEXT.md glossary.

## Measured outcome (standalone harness, real render)

| Variant | Card right edge | Overlay scrollbar | Gap |
| --- | --- | --- | --- |
| base (no gutter) | ~347 pt | ~350–360 pt | ~3 pt (touching) |
| content padding (fix) | ~330 pt | ~350–360 pt | ~20 pt — scrollbar pinned right, cards clear |
| `contentMargins(for: .scrollContent)` | ~330 pt | ~334–344 pt | ~4 pt — scrollbar followed the content |

## Verification pattern when the NSPopover can't be captured

Drive-through automation (cua-driver) often cannot enumerate/occupy a menu-bar `NSPopover`
window. Instead reproduce the **exact modifier chain** in a minimal standalone SwiftUI
windowed executable (`swiftc -parse-as-library file.swift`; launch with the variant behind
an env var; capture the window; measure). This exercises the real SwiftUI/scrollbar engine
and gives reliable before/after geometry for the scrollbar↔card relationship. Report the
on-pixel check of the final NSPopover as a manual step, not a machine-verified pass.

## Pixel measurement without PIL

`vision_analyze` returns unreliable magnitude/region estimates for tiny scrollbars. Decode
the PNG by hand (struct + zlib, main-loop PNG unfilter for Sub/Up/Average/Paeth, RGBA where
alpha 0 = transparent) and profile:
- thin light-gray overlay scrollbar thumb ≈ column-mean brightness > ~110–115, a ~11pt
  vertical stripe;
- card right edge = last column with brightness in ~40–90 (dark card bg), dropping to black
  beyond;
- compare columns/edges across variants at the same window config, not across different
  captures with differing width/scale (Retina @2x = 2 physical px per pt).