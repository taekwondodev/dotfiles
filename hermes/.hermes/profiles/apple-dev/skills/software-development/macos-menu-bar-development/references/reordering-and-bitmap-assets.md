# MenuBarExtra reordering and bitmap assets

## Persistent card order

- Use a versioned, namespaced `UserDefaults` key such as `subscriptionOrder.v1`.
- Normalize unknown values and duplicates, then append the deterministic default order.
- Derive visible cards from saved order and append providers missing from it.
- Provide VoiceOver/keyboard alternatives such as `Sposta prima` and `Sposta dopo`.
- Compute accessible moves against visible cards, not hidden providers in the full persisted order.
- Show a clear drop-target highlight.
- In `MenuBarExtra(.window)`, prefer `onDrop(of:isTargeted:perform:)` with explicit internal drag state when a `DropDelegate` does not receive drops reliably. Validate the dragged identity and clear drag/target state on completion or rejection.
- Test normalization, persisted order, partial-provider movement, boundary moves, and before-target ordering independently of SwiftUI rendering.

## Bitmap icon loading

If `Image(name, bundle: .module)` renders an empty placeholder while processed resources are present, load the URL explicitly with `NSImage(contentsOf:)` and render with `Image(nsImage:)`. Keep a visible fallback. Verify source files and the release resource bundle separately; a test runner's `Bundle.module` may not mount an executable target's processed resources even though the actual app bundle does.
