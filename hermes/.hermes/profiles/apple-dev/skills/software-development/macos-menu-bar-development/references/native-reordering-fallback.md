# Native macOS card reordering fallback

The newer SwiftUI APIs `reorderable()` and `reorderContainer(for:)` may be documented for a future SDK but unavailable in the installed toolchain. Verify by compiling a minimal use before designing around them.

For a macOS `MenuBarExtra` utility, use the supported fallback:

- Replace the custom `ScrollView` card stack with a `List` when pointer reordering is required.
- Put the card `ForEach` inside the `List` and attach `.onMove(perform:)`.
- Keep the existing persisted order model and accessible `Sposta prima`/`Sposta dopo` actions.
- Let `List` own the drag placeholder, row movement, and scrolling; custom `onDrag`/`onDrop` handlers attached to cards can fail to receive drops reliably in a `MenuBarExtra`.
- Test the order model independently; pointer drag remains a manual smoke check on the actual built menu-bar executable.

The article consulted for this path: https://www.theswift.dev/posts/swiftui-reorderable-drag-and-drop/
