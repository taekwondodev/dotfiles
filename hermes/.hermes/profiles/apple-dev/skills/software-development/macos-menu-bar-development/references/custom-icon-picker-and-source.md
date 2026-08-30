# Custom menu-bar icon picker and source selection

Use this reference before replacing a SwiftUI `MenuBarExtra` identity mark.

## Design comparison

Do not choose a menu-bar icon from an isolated large preview. Build a disposable picker with 3–4 variants and a mock menu bar showing the candidate beside CPU/RAM and system-style extras. Compare:

- filled vs outline stroke style;
- line weight;
- visible artwork bounds rather than file canvas bounds;
- vertical centering;
- optical gap between compound marks;
- light/dark template behavior.

A custom mark can be recognizable yet still look wrong if it is much heavier or more solid than neighboring menu-bar extras.

## Asset-source rule

Keep the Finder App Icon and provider identity assets in the Apple asset catalog. A menu-bar mark may be an explicit raw-resource exception when a catalog/PDF artboard introduces excessive transparent padding or SwiftUI renders the full artboard unexpectedly. Document the exception and keep its generator reproducible.

## Validated H-plus-sparkle path

For a horizontal H-plus-sparkle mark:

1. Generate a tightly cropped transparent PNG whose canvas follows the visible mark; avoid large transparent top/bottom padding.
2. Load it as `NSImage` from the SwiftPM resource bundle.
3. Mark monochrome art as `isTemplate = true`.
4. Use the `MenuBarExtra` label form with `Label { Text(...) } icon: { ... }`.
5. Preserve the image ratio and set `image.size.height = 18`, then `image.size.width = 18 / ratio` before creating `Image(nsImage:)`.
6. Rebuild, reinstall, relaunch, and inspect the live menu bar. A successful build, resource lookup, or `Assets.car` listing is not visual proof.

This workflow fixed a tiny custom icon caused by transparent canvas padding and a full-artboard rendering issue. It also avoids relying on `.frame(width: 18, height: 18)` to size a large source canvas.
