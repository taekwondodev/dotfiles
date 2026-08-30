# Identity icon and resource-bundle smoke checks

Use this checklist when a SwiftUI `MenuBarExtra` shows missing or invisible provider icons.

1. Keep bitmap assets under the executable target's processed `Resources/` directory and verify their copied files in the release resource bundle after `swift build -c release`.
2. Centralize asset names in a catalog so the view and tests cannot drift.
3. Use `Image(name, bundle: Bundle.module)` (or an explicit bundle captured by the app target), `.renderingMode(.original)`, high-quality interpolation, and a contrasting container/border.
4. Inspect the actual source images at card size: valid files can still look invisible because of template rendering, poor contrast, oversized canvas, or stale app processes.
5. Do not assume `Bundle.module` from a separate test runner proves executable-target resources are mounted. Combine a source/resource contract test with an explicit release-bundle file check.
6. Relaunch the actual menu-bar executable after changes and verify the live popover; unit tests and compilation cannot prove visual rendering.

For `MenuBarExtra(.window)` sizing, `ScrollView` needs explicit width plus stable `minHeight`/`idealHeight` and `maxHeight`; max-only sizing can collapse to an almost empty popover.