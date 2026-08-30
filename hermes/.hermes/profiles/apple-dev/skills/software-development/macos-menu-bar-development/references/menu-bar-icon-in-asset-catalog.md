# Menu-bar icon in the asset catalog (user preference + reversal)

The user's standing preference for HermesUsageMonitor (and personal menu-bar utilities):
the Apple asset catalog (`Media.xcassets`) is the **single source of truth** for every
visual — the Finder App Icon, provider identity icons, AND the menu-bar mark.

## What the user wants

- Menu-bar icon lives in `Media.xcassets/<Name>.imageset/` as a PNG image set.
- `Contents.json`:
  ```json
  {
    "images": [ { "filename": "<Name>.png", "idiom": "universal", "scale": "1x" } ],
    "properties": { "template-rendering-intent": "template" }
  }
  ```
- Runtime loads it with `NSImage(named: "<Name>")` in the `MenuBarExtra` label view.
- Delete the raw PNG from `Resources/` (no raw-resource exception).
- Delete the SwiftUI fallback mark (e.g. `HermesMark`) — the icon exists, no fallback.

## Reversal to remember

Earlier guidance treated the menu-bar mark as an explicit raw-resource exception
(loaded via `Bundle.module.url(forResource:)`, possibly with a SwiftUI fallback).
The user rejected that on an actual icon: keep it in the catalog. Do not reintroduce
a raw `Resources/` PNG or a fallback view unless the user asks.

## After moving the icon into the catalog

- Update the resource test to assert the **image set** exists in the catalog
  (e.g. `Media.xcassets/<Name>.imageset/Contents.json`), not a raw `Resources/` PNG.
- `actool` (run by `build-app.sh`) fails while `Contents.json` names a file that is
  not yet inside the imageset. So: verify with `swift test` / `swift build` first
  (neither runs `actool`), and only run `build-app.sh` once the PNG file is actually
  in the imageset folder.
- A menu bar item that is clickable but shows nothing usually means the image's
  runtime load resolves to empty — confirm the asset is really named/placed as the
  `NSImage(named:)` expects before chasing sizing/padding.
