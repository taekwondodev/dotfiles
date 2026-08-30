# Custom Menu Bar Icon Sizing

Use this when a custom `MenuBarExtra` icon looks enormous or tiny.

1. Inspect visible artwork bounds, not only the file canvas bounds. Large transparent padding makes a short horizontal mark render tiny even when `NSImage.size` is 18×18.
2. Prefer a tightly cropped transparent asset whose aspect ratio matches the visible mark. For an 18 pt menu-bar height, a horizontal H-plus-sparkle asset may be roughly 60×36 px at 2×.
3. Use the `MenuBarExtra` label form with `Label { Text(...) } icon: { ... }`.
4. Load the file as `NSImage`, mark monochrome art as `isTemplate = true`, preserve its ratio, and set `image.size.height = 18; image.size.width = 18 / (image.size.height / image.size.width)` before creating `Image(nsImage:)`.
5. Do not rely on `.frame(width: 18, height: 18)` to correct an oversized canvas; it can scale the canvas rather than the visible artwork.
6. Rebuild, reinstall, relaunch the actual menu-bar app, and inspect the live result. Unit tests and `Assets.car` inspection cannot prove visual menu-bar geometry.

This was validated for a custom H-plus-sparkle icon derived from a Finder App Icon; the root cause of the tiny result was transparent canvas padding, not PNG alpha or `MenuBarExtra`.
