# Picker-to-runtime visual scale

When choosing a custom `MenuBarExtra` icon from a mockup, the mockup's visible icon height is a design input, not decoration. Record the approved target height and use the same value in the live `NSImage` sizing code.

For a tight horizontal H-plus-sparkle PNG, load the image from the executable target's `Bundle.module` resource bundle, set `isTemplate = true`, compute `ratio = image.size.height / image.size.width`, then set `image.size.height = approvedTargetHeight` and `image.size.width = approvedTargetHeight / ratio` before creating `Image(nsImage:)` inside a `Label` passed to `MenuBarExtra`.

Do not rely on `.frame(width:height:)` to prove parity: it may scale the source canvas rather than the visible artwork. Compare the live installed menu-bar screenshot with the picker beside the same CPU/RAM/system icons. A build, unit test, resource lookup, or Assets.car inspection does not prove visual size.

If the live result is smaller than the approved picker, first compare target heights and visible artwork bounds before changing the icon geometry.
